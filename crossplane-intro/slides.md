# Crossplane in 10 Minutes

### From infrastructure provisioning to platform abstractions

---

# What is Crossplane?

<div style="display: flex; align-items: center;" data-markdown>

<div style="flex: 1;"> <!-- 20% Breite -->

<img src="assets/crossplane-icon.svg" style="max-height: 220px; width: auto; object-fit: contain;">

</div>

<div style="flex: 4; text-align: left;"> <!-- 80% Breite -->

<div style="margin-left: -1.2em;">

* Kubernetes-native control plane
* Uses k8s APIs to manage external and in-cluster resources
* Can provision infrastructure like databases, S3 buckets
* Bigger value: higher-level abstractions for platform teams
* CNCF **Graduated** project since **October 28, 2025**

</div>

</div>

</div>

---

# MR - Managed Resources

<div style="font-size: 0.9em;">

* Managed Resources are provider-specific Kubernetes custom resources
* Crossplane Providers install these resource APIs from the provider ecosystem
* They represent concrete things Crossplane can reconcile
* Often external infrastructure, but can also model other systems


```text
Examples:

- S3 Bucket
- Postgres Database
- Vault Secret Engine
- GitHub Repository
- Kubernetes Object (Deployment)
```

* MR = building block, not usually the final platform API

</div>

---

# What does a Managed Resource look like?

```yaml
# install SQL provider
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: crossplane-contrib-provider-sql
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-sql:v0.15.0
```

```yaml
# instantiate a DB
apiVersion: postgresql.sql.crossplane.io/v1alpha1
kind: PostgresDatabase
metadata:
  name: appdb
spec:
  forProvider:
    version: "16"
    size: small
    storageGB: 20
```

### Crossplane provisions infrastructure from Kubernetes

---

## Myth: "Crossplane is strictly for infrastructure"

* Reality: more than infrastructure resources like databases
* Can bind infrastructure and application configuration declaratively
* Composite Resource Definitions (XRDs) and Compositions

---

# Composite Resource Definitions (XRDs)

* They describe the schema and required fields
* They define user-facing APIs for platform consumers

```yaml []
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
spec:
  group: example.com
  names:
    kind: RazorApp
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        properties:
          spec:
            type: object
            required: [projectName]
            properties:
              projectName: { type: string }
```

* XRD = the API contract for platform consumers

---

# Compositions

* They implement the user-facing API defined by the XRD
* They map one platform API object to one or more resources

```yaml []
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
spec:
  compositeTypeRef:
    kind: RazorApp
  resources:
    - name: db
      base:
        kind: PostgresDatabase
    - name: app
      base:
        kind: Object
        spec:
          forProvider:
            manifest:
              kind: Deployment
```

* Composition = how the platform API is realized

---

# Composite Resources (XRs)

* XRs are instances of the API defined by the XRD
* Users create them to request a platform outcome
* Unlike Helm, this is realized and reconciled in-cluster

```yaml []
apiVersion: example.com/v1alpha1
kind: RazorApp
metadata:
  name: blade
spec:
  projectName: blade
```

* XR = one concrete request against the platform API

---

# What this enables

* Platform team defines a higher-level API
* Application teams use that API instead of raw resources
* One XR creates multiple resources with guardrails and defaults
* That API can combine infra and app-facing k8s objects

---

# Two Integration Patterns

* Crossplane can complement developer-owned Helm charts
* Or it can fully abstract app + infra behind one platform API

```text
Plan A: Crossplane inside the app chart
Plan B: Helm inside the platform composition
```

* Both patterns are valid, depending on platform ownership

---

# Plan A: Crossplane inside the App Chart

* Developers keep owning the Helm chart
* The chart renders namespaced Crossplane resources from `values.yaml`
* App config and infra requests stay versioned together

```yaml []
# values.yaml
global:
  projectName: blade
capabilities:
  database:
    enabled: true
    size: small

# templates/database.yaml
kind: PostgresDatabase
metadata:
  name: {{ .Values.global.projectName }}-db
spec:
  size: {{ .Values.capabilities.database.size }}
```

* Trade-off: familiar flow, but developers still own Helm complexity

---

# Plan B: Helm inside the Composition

* Developers submit one simple platform XR
* The platform Composition creates infra and deploys the developers' Helm chart
* The platform team owns more abstraction and more maintenance

```yaml []
# developer input
kind: RazorApp
spec:
  projectName: blade

# composed resources
- kind: PostgresDatabase
- kind: Release
  chart: dev-team/blade
```

<div style="font-size: 0.9em;">

* Trade-off: simpler for devs, Helm complexity shifts to the platform team

</div>

---

# Crossplane vs Pipeline + Terraform

* Pipelines run intermittent CLI steps from the outside
* Crossplane runs a continuous reconciliation loop in-cluster

```text
Pipeline + Terraform:
Git Commit
  -> CI Pipeline
      -> Terraform
      -> Argo CD
```

```text
Crossplane:
Git Commit
  -> Argo CD
      -> Crossplane Managed Resources -> Cloud API
      -> Application Pods / Services
```

* Intermittent CLI orchestration vs. continuous in-cluster reconciliation

---

# App-Centric Delivery Comparison

* Crossplane can live directly in the application lifecycle
* This matters most when infra is coupled to app rollout

```text
Crossplane (Plan A):
- App chart emits pods and infra manifests together
- Argo CD syncs both in one flow
- Deleting the namespace also removes the infra objects
```

```text
Pipeline + Terraform:
- Terraform does not fit naturally into the app chart model
- App and infra lifecycles drift apart more easily
- Namespace deletion alone does not clean up cloud resources
```

* Crossplane fits better when app and infra should behave as one unit

---

# Platform Trade-offs

* The real choice is where your team wants complexity to live

```text
Pipeline + Terraform
+ broad ecosystem
+ simple CI logs
- more glue code
- more drift risk
```

```text
Crossplane
+ self-healing control plane
+ no separate infra pipeline
- steeper learning curve
- more platform control plane overhead
```

* Crossplane centralizes complexity inside the control plane

---

# Greenfield Strategy

* If you start fresh, you can skip years of pipeline glue code
* Kubernetes becomes the unified engine for app and infra delivery
* Guardrails live in XRDs and Compositions, not in CI scripts
* GitOps becomes continuous reconciliation, not point-in-time automation

```text
App-centric platform goal:

- infra lives with the app Helm chart
- developers use safe platform APIs
- no separate Terraform orchestration layer
```

* For this model, Crossplane is often the more natural starting architecture

---

# Where it fits well

* Internal developer platforms
* Golden paths for app teams
* Standard environments for services
* Cloud resource provisioning with policy and defaults
* Bundling infra setup with application rollout prerequisites
