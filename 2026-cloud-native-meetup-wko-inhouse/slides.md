# GitOps Visibility
## Precise Argo CD diffs on every Pull Request

---

<section id="speaker-page">
  <style>
    /* Das Styling greift nur innerhalb dieser Sektion mit der ID #speaker-page */
    #speaker-page .round-img {
      width: 250px !important;
      height: 250px !important;
      object-fit: cover;
      border-radius: 50%;
      border: 5px solid #93a1a1;
      margin: 0 auto 20px auto !important;
      display: block;
    }
    #speaker-page h2 {
      color: #93a1a1;
    }
  </style>

  # About me

<div style="display: flex; align-items: center; justify-content: center; gap: 20px;" data-markdown>
  
  <div style="flex: 2; font-size: 0.8em;"> <!-- 33% Breite -->

  <img src="assets/ch0_robert_klonner.jpeg" class="round-img">

### Robert Klonner

  </div>

  <div style="flex: 3; text-align: left; font-size: 0.8em; display: grid; align-content: center;"
  <!-- Leerzeile für Markdown -->

### Facts
  * *DevOps Engineer @ WKO Inhouse GmbH*
  * *CNCF Golden Kubestronaut*
  * GitOps, Platform Engineering, CI/CD

### Background
* DevOps – CI/CD, SDLC Toolchain, Operations
* Python Developer - Scripting, Web development, Data processing

### Contact
* r@klonner.cc
* https://www.linkedin.com/in/klonner-robert/
  </div>

</div>

---
# Agenda

* Chapter 1: The problem with templating layers in GitOps

* Chapter 2: A solution for more visibility

* Chapter 3: A production setup

* Chapter 4: Use cases 

---

# Chapter 1: The problem with templating layers in GitOps

---

# DRY in GitOps

* **Resource Manifests** → Helm | Kustomize

* **Application Manifests (Argo CD)** → ApplicationSets | App of apps

* 👍 Maintainable and efficient

* 👎 High Cognitive Load for changes → 🤯


---

# git-diff | rendered-diff | argocd-diff

* Pull requests - git-diff of templating language (DRY) - not rendered!

* Dev maybe rendered template locally but no info for reviewer in PR

* Reviewer could manually create rendered-diff → not feasible and error prone

* Argo CD is a additional layer before a cluster deployment (Manifests, App of apps, Application Sets)

---

# Example - Change replicas in Helm

Task: Increase replicas for a production environment

<div class="r-stack">
  <img
    class="fragment"
    src="assets/ch1_example2_change_replica1.png"
    style="max-height: 400px; width: auto; object-fit: contain;"
  />

  <div class="fragment" style="background: #002b36; color: #93a1a1; padding: 20px; max-width: 400px;">
    <p>We merge PR</p>
    <p>Argo CD syncs</p>
    <p>Nothing happens?</p>
    <p>Debugging... 😕</p>
  </div>

  <div class="fragment" style="width: 70%; min-width: 400px;">

```bash
  helm template my-app/ -f values/prd.yaml
```

  ```yaml [12]
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-namespace
  labels:
    helm.sh/chart: myApp-0.1.0
    app.kubernetes.io/name: myApp
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: myApp
      app.kubernetes.io/instance: release-name
  ```
  </div>

  <img
    class="fragment"
    src="assets/ch1_example2_change_replica2.png"
    style="max-height: 400px; width: auto; object-fit: contain;"
  />
</div>

---

# Example - Conditionals in Helm chart

<div style="display: flex; align-items: center;" data-markdown>
  <div style="flex: 3;"> <!-- 66% Breite -->

  <!-- ![Breites Bild](assets/ch1_example_change_applicationset_portrait.png) -->
  <img src="assets/ch1_example_helm_configurable_livenessprobe1.png">
  </div>

  <div style="flex: 2;"> <!-- 33% Breite -->

  - Task: Enable configureable liveness probes

  - Max: "Checkout this PR - it's just a minor change on the liveness probe..."

  - Reviewer: 🤔
  </div>
</div>

---

# Possibilities for diff generation in the CLI

<div style="font-size: 0.6em;">

| Layer | Command | What is rendered? | Focus |
| :--- | :--- | :--- | :--- |
| **Tooling** | `helm template` / `kustomize build` | Kubernetes ressources (local) | Validating pure Helm/Kustomize-logic without Argo CD. |
</div>

---

# Example - Modifying an ApplicationSet


<div style="display: flex; align-items: center;" data-markdown>

  <div style="flex: 3;"> <!-- 66% Breite -->

  <!-- ![Breites Bild](assets/ch1_example_change_applicationset_portrait.png) -->
  <img src="assets/ch1_example_change_applicationset_portrait.png">
  </div>

  <div style="flex: 2;"> <!-- 33% Breite -->

  - Task: Refactoring List Generator → Git Generator Directories

  - Is the ApplicationSet delivering staging and production as before? 🤔

  - Verification would require Argo CD object rendering
  </div>
</div>

---

# Possibilities for diff generation in the CLI

<div style="font-size: 0.6em;">

| Layer | Command | What is rendered? | Focus |
| :--- | :--- | :--- | :--- |
| **Template** | `argocd appset generate -o yaml` | `kind: Application` | Name, Target-Cluster, Paths & Parameter-Mapping. |
| **App-Logic** | `argocd app manifests <NAME>` | `kind: Deployment`, etc. | Actual Kubernetes ressources (only when app exists). |
</div>

---

# Chapter 2: A solution for more visibility

---

# Potential approaches for a solution 

<ul>
<li class="fragment">

**CI Pipeline Diff (`helm template | kustomize build`)**
  * render two times (`main | change`) in pipeline 
  * effort and not unform across tool/project
</li>

<li class="fragment">

**Argo CD Diff in UI**
  * auto-sync must be deactivated
  * Diff only visible when PR is already merged
</li>

<li class="fragment">

**Rendered Manifest Pattern**
  * two branches or repos to 'store' rendered manifests
  * additional complexity
  * e.g. Argo CD Source Hydrator (alpha feature)
</ul>
---

#  Required steps

<div class="fragment">

## Integrate in CI Prozess 
triggering a CI process like Atlantis for terraform → not local
</div>

<div class="fragment">

## Rendering all templating layers
resolving the contexts of Helm | Kustomize + Argo CD manifest
</div>

<div class="fragment">

## Visualizing the Diff
for desired cluster state - main vs change 
</div>

---
# Is there already a tool available?

<img src="assets/ch1_argocd_diff_preview_logo.png"
     style="max-height: 350px; width: auto; object-fit: contain;">
<!-- .element: class="fragment" -->

---

# Argo CD Diff Preview - How it works

<div style="display: flex; align-items: center; gap: 50px;" data-markdown>

  <div style="flex: 1;"> 
    <img src="assets/ch2_diff_live_state_vs_git_portrait.png"
         style="max-height: 400px; width: auto; object-fit: contain;">

  </div>

  <div style="flex: 4; text-align: left;"> <!-- 33% Breite -->

#### Compare desired state of two branches → reproduceable
  * no live state (temporary drift, admission webhooks, sync delays ...)
  * GitOps == auto-sync enabled → comparision of desired state is sufficient

#### Performing the rendering with Argo CD
  * extensive rendering features, not feasible to reproduce in a pipeline
  </div>
</div>

---

# Argo CD Diff Preview - How it works

Example execution

```bash [1-3|5-7|9-11,18|14-15|16-17]
# Get Argo CD Manifests on main branch
git clone https://github.com/dag-andersen/argocd-diff-preview \
          base-branch --depth 1 -q 

# Get Argo CD Manifests on target branch
git clone https://github.com/dag-andersen/argocd-diff-preview \
          target-branch --depth 1 -q -b helm-example-3

# Execute Argo CD Diff Preview (e.g. in a container)
docker run \
  --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd)/output:/output \
  -v $(pwd)/base-branch:/base-branch \
  -v $(pwd)/target-branch:/target-branch \
  -e REPO=dag-andersen/argocd-diff-preview \
  -e TARGET_BRANCH=helm-example-3 \
  dagandersen/argocd-diff-preview:v0.2.1
```

---

# Argo CD Diff Preview - How it works

Example output

<img src="assets/ch2_argocd_diff_preview_terminal_output.png"
     style="max-height: 500px; width: auto; object-fit: contain;">

---

# Argo CD Diff Preview - Example output

Diff Preview as interactive HTML within a Pull Request comment

<iframe data-src="assets/ch1_argocd_example_diff.html" 
        style="background: #0d1117; border: 1px solid #30363d; border-radius: 6px;" 
        width="800" height="500">
</iframe>

---

# Argo CD Diff Preview - How it works

<div style="display: flex; align-items: center; gap: 50px;" data-markdown>

  <div style="flex: 3;"> 
    <img src="assets/ch2_ephemeral_vs_preinstalled_mode.png" 
         style="max-height: 600px; width: auto; object-fit: contain;">
  </div>

  <div style="flex: 3; text-align: left;"> <!-- 33% Breite -->

### 1. Argo CD instance for rendering

#### Ephemeral
* Create kind cluster
* Deploying Argo CD

#### Pre-Installed
* Providing a dedicated Argo CD instance
  </div>
</div>

---

# Argo CD Diff Preview - How it works

<div style="display: flex; align-items: center;" data-markdown>

  <div style="flex: 3;"> 
    <img src="assets/ch1_argocd_diff_preview_application_patching.png" 
         style="max-height: 550px; width: auto; object-fit: contain;">
  </div>

  <div style="flex: 2; text-align: left;"> <!-- 33% Breite -->

### 2. Preparing application manifests

* Fetch
* Select/Filter
* Patch 
  </div>
</div>

---

# Argo CD Diff Preview - How it works

<div style="display: flex; align-items: center; gap: 50px;" data-markdown>

  <div style="flex: 2;"> 
    <img src="assets/ch1_argocd_diff_preview_application_rendering.png" 
         style="max-height: 600px; width: auto; object-fit: contain;">
  </div>

  <div style="flex: 3; text-align: left;"> <!-- 33% Breite -->

### 3. Argo CD Applications deployen

* Resolving ApplicationSets and App of Apps → Applications
* Renderning the applications for main and change in Argo CD
* Creating applications (deactivated sync)
* Extracting both variants
  ```bash
  argocd app manifests <app-name>
  ```
* Deleting the applications
  </div>
</div>

---

# Argo CD Diff Preview - How it works

### 4. Create Diff
Compare main vs change branch per Argo CD application:

* Added applications - new in change branch
* Removed applications - deleted in change branch
* Modified applications - modified between branches
* Unchanged applications - unchanged (filtered in output)

<div style="font-size: 0.6em; margin-top: 1em">

| File | Description |
| :--- | :--- |
| `./output/diff.md` | Markdown diff ... |
| `./output/diff.html` | HTML diff ... |
</div>

---

# Chapter 3: A production setup

---

# Focus on
<div class="fragment">

## Performance
for feedback in PR (seconds)
</div>

<div class="fragment">

## Security
securing production cluster, least priviledge CI access
</div>

<div class="fragment">

## Maintenance | Operations
minimize effort
</div>

---

# Argo CD installation for Diff Preview

<div style="text-align: left;" class="fragment">

### Ephemeral

* ✅ No setup needed
* ✅ Complete isolation
* ❌ Slow (~60 seconds overhead per run)
* ❌ Credentials in CI/CD pipeline

</div>

<div style="text-align: left;" class="fragment">

### Pre-Installed
* ✅ Fast execution (Overhead only for Gitlab Runner spin-up-time)
* ✅ No cluster credentials in CI pipeline (Using dedicated service account within the cluster, Argo CD manages all credentials)
* ❌ More complex (needs self-hosted runners + dedicated Argo CD)
</div>

---

# Argo CD Pre-installed

![argocd_diff_preview](assets/ch3_pre_installed_argocd2.png)

---

# Argo CD Pre-installed - Deployment

<div style="display: flex; align-items: center; gap: 50px;" data-markdown>
  <div style="flex: 3; text-align: left;" class="fragment"> <!-- 33% Breite -->

## Openshift GitOps Operator
* Declarative installation of dedicated instance
* Same version as production Argo CD
* Upgrades are in sync

<div class="fragment">

## Configuration via GitOps

* Service Account (Gitlab runner access)
* RBAC Service Account
* SSH known hosts, TLS certs
* Repo Credential Templates (VSO|ESO)
* Cluster Credentials (VSO|ESO)
...
</div>
</div>

  <div style="flex: 1;" data-markdown> <!-- .element: class="fragment fade-up" -->
    <img src="assets/ch3_argo_in_jail.png" style="max-height: 600px; width: auto; object-fit: contain;">

#### Namespaced 
#### (not cluster-wide)
  </div>
</div>
---

# Gitlab Runner image

Argo CD Diff Preview binary (no DinD) + Dependencies

```dockerfile [6-11|13-17|19-23|25-31]
FROM registry.access.redhat.com/ubi10-minimal:latest

RUN microdnf install -y curl git tar unzip && \
    rm -rf /var/cache/yum/*

# argocd CLI (optional)
# only needed if using --render-method=cli
RUN curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
    install -m 555 argocd-linux-amd64 /usr/local/bin/argocd && \
    rm argocd-linux-amd64 && \
    argocd version || true

# argocd-diff-preview CLI
RUN curl -LJO https://github.com/dag-andersen/argocd-diff-preview/releases/download/v0.2.1/argocd-diff-preview-Linux-x86_64.tar.gz && \
    tar -xvf argocd-diff-preview-Linux-x86_64.tar.gz && \
    mv argocd-diff-preview /usr/local/bin && \
    argocd-diff-preview --version

# kubectl CLI
# dependency of argocd-diff-preview, utilized by go k8s-client
RUN curl -LO https://dl.k8s.io/release/v1.34.0/bin/linux/amd64/kubectl && \
    install -m 555 kubectl /usr/local/bin/kubectl && \
    rm -f kubectl

# oc CLI
# utilized by runner to login to openshift with the argocd-diff-preview-access service account
# e.g. oc login --server "$OPENSHIFT_SERVER" -token="$ARGOCD_DIFF_PREVIEW_OPENSHIFT_SA_TOKEN"
RUN curl -L -o /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz && \
    tar -xzvf /tmp/oc.tar.gz -C /usr/local/bin oc && \
    chmod +x /usr/local/bin/oc && \
    rm -f /tmp/oc.tar.gz
```

---

# Gitlab pipeline template

central and versioned

```yaml [9|10-16|19-25|27-29|31-33|35-41|49-54|56-60|63-64]
default:
  tags:
    - openshift-gitlab-runner

stages:
  - diff

diff:
  image: <your-registry>/argocd-diff-preview-runner
  variables:
    ARGO_MANIFEST_REPO: ""
    ARGO_MANIFEST_REPO_TARGET_BRANCH: ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}
    K8S_MANIFEST_BRANCH: ${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME}
    ARGOCD_DIFF_PREVIEW_FLAGS: ""  # e.g. "--debug"
    OPENSHIFT_CLUSTER: "<your-openshift-cluster-url>"
    GITLAB_TOKEN: $GITLAB_PAT
  script:
    - echo "******** Running analysis ********"
    # Repo location of the ArgoCD ApplicationSet manifests
    - |
      if [ -z "$ARGO_MANIFEST_REPO" ]; then
        ARGO_MANIFEST_REPO=${CI_REPOSITORY_URL}
      else
        ARGO_MANIFEST_REPO="https://$ARGOCD_DIFF_PREVIEW_REPO_USER:$ARGOCD_DIFF_PREVIEW_REPO_PASSWORD@$ARGO_MANIFEST_REPO"
      fi

    - git clone ${ARGO_MANIFEST_REPO} base-branch --depth 1  -q
    - git clone ${ARGO_MANIFEST_REPO} target-branch --depth 1 -q \
      -b ${ARGO_MANIFEST_REPO_TARGET_BRANCH}

    # initiate kubeconfig creation that argocd-diff-preview can use
    - oc login --server "$OPENSHIFT_CLUSTER" \
               --token="$ARGOCD_DIFF_PREVIEW_OPENSHIFT_SA_TOKEN"
    - |
      argocd-diff-preview \
        --repo ${CI_MERGE_REQUEST_PROJECT_PATH} \
        --base-branch main \
        --target-branch ${K8S_MANIFEST_BRANCH} \
        --argocd-namespace=argocd-diff-preview \
        ${ARGOCD_DIFF_PREVIEW_FLAGS} \
        --create-cluster=false
    - |
      # Deleting old PR comment if exists
      jq --null-input --rawfile msg $(pwd)/output/diff.md '{body: $msg}' > pr_comment.json
      NOTE_ID=$(curl --silent --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
          "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/merge_requests/${CI_MERGE_REQUEST_IID}/notes" | \
          jq '.[] | select(.body | test("Argo CD Diff Preview")) | .id')

      if [[ -n "$NOTE_ID" ]]; then
          echo "Deleting existing comment (ID: $NOTE_ID)..."

          curl --silent --request DELETE --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
              --url "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/merge_requests/${CI_MERGE_REQUEST_IID}/notes/${NOTE_ID}"
      fi

      echo "Adding new PR comment..."
      curl --silent --request POST --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
          --header "Content-Type: application/json" \
          --url "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/merge_requests/${CI_MERGE_REQUEST_IID}/notes" \
          --data @pr_comment.json > /dev/null

      echo "Comment added!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

---

# Gitlab pipeline - Including a Diff Preview

* opt-in (activation per pipeline)
* minimal configuration

```yaml []
stages:
  - argocd-diff-preview
include:
  - project: 'gitlab-ci-templates'
    ref: 'main'
    file: 'argocd-diff-preview-merge-request.yml'
diff:
  extends: .template-argocd-diff-preview
  stage: argocd-diff-preview
  variables:
    ARGOCD_DIFF_PREVIEW_FLAGS: "--debug  --max-diff-length 131072"
```

---

# Gitlab Runner Execution time

* Gitlab Runner ~10-20 seconds
* Diff Preview ~10 seconds

![](assets/ch3_gitlab_runner_performance.png)

---

# Chapter 4: Use Cases

---

## Zero-Change PR - Duplicated Helm chart per env → Central chart

* Create central chart + value files
* Modify Argo CD manifest to use chart + value files

<div class="r-stack">
  <img
    src="assets/ch4_uc_refactor_helm_per_env_to_central_chart1.png"
    style="max-height: 450px; width: auto; object-fit: contain;"
  />
  <img
    class="fragment"
    src="assets/ch4_uc_refactor_helm_per_env_to_central_chart2.png"
    style="max-height: 500px; width: auto; object-fit: contain;"
  />
  <img
    class="fragment"
    src="assets/ch4_uc_refactor_helm_per_env_to_central_chart3.png"
    style="max-height: 500px; width: auto; object-fit: contain;"
  />
  <img
    class="fragment"
    src="assets/ch4_uc_refactor_helm_per_env_to_central_chart4.png"
    style="max-height: 500px; width: auto; object-fit: contain;"
  />
  <img
    class="fragment"
    src="assets/ch4_uc_refactor_helm_per_env_to_central_chart5.png"
    style="max-height: 500px; width: auto; object-fit: contain;"
  />
</div>

---

## Zero-Change PR - Duplicated Helm chart per env → Central chart

Issue: Prd ServiceAccount and Service have "dev" suffix...

<iframe data-src="assets/ch4_uc_helm_per_env_to_central_chart_diff_preview.html" 
        style="background: #0d1117; border: 1px solid #30363d; border-radius: 6px;" 
        width="800" height="500">
</iframe>

---

## Zero-Change PR - Duplicated Helm chart per env → Central chart

```yaml [5]
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-dev
  labels:
    {{- include "myApp.labels" . | nindent 4 }}
```

no templating of the name in one ressource

```yaml
myapp-{{ .Values.environment }}
```

---

## Zero-Change PR - Kustomize refactoring

Change that was promoted through all overlays → Back-to-Base

<div class="r-stack">
  <img
    class="fragment"
    src="assets/ch4_uc_kustomize_backtobase0.png"
    style="max-height: 450px; width: auto; object-fit: contain;"
  />
  <img
    class="fragment"
    src="assets/ch4_uc_kustomize_backtobase1.png"
    style="max-height: 500px; width: auto; object-fit: contain;"
  />
  <img
    class="fragment"
    src="assets/ch4_uc_kustomize_backtobase2.png"
    style="max-height: 500px; width: auto; object-fit: contain;"
  />
  <img
    class="fragment"
    src="assets/ch4_uc_kustomize_backtobase3.png"
    style="max-height: 500px; width: auto; object-fit: contain;"
  />
</div>

---

## Zero-Change PR - Kustomize refactoring

No change → Successful refactoring!

<iframe data-src="assets/ch4_uc_kustomize_backtobase_diff_preview.html" 
        style="background: #0d1117; border: 1px solid #30363d; border-radius: 6px;" 
        width="800" height="500">
</iframe>

---

## Deploying a productline with an ApplicationSet

Verifying the onboarding of a new project 

<div class="r-stack">
  <img
    src="assets/ch4_uc_appset_projects1.png"
    style="max-height: 500px; width: auto; object-fit: contain;"
  />
  <div class="fragment">

```yaml [10-12|14-17|20|24]
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: project-deployment
spec:
  generators:
    - matrix:
        generators:
          # 1) Read list of projects (projects.json) from a configuration repo
          - git:
              files:
                - path: projects.json
          # 2) For each listed project, discover applications, components, and environments
          - git:
              # repo path structure: env/appName/component
              directories:
                - path: '{{ .env }}/{{ .app_name }}/*'
  template:
    metadata:
      name: '{{ .values.appName }}-{{ .values.component }}-{{ .values.env }}'
    spec:
      destination:
        server: 'https://kubernetes.default.svc'
        namespace: '{{ .values.appName }}-{{ .values.component }}-{{ .values.env }}'
```
</div>

  <img
    class="fragment"
    src="assets/ch4_uc_appset_projects2.png"
    style="max-height: 500px; width: auto; object-fit: contain;"
  />
</div>

---

## Deploying a productline with an ApplicationSet

Project and applications are discoved and rendered correctly

<iframe data-src="assets/ch4_uc_appset_projects.html" 
        style="background: #0d1117; border: 1px solid #30363d; border-radius: 6px;" 
        width="800" height="500">
</iframe>

---

## Summary - Argo CD Diff Previews

<div style="text-align: left; font-size: 0.8em; width: fit-content; margin: 0 auto;"">

<div class="fragment">

### Use cases
* Pre-render simple to complex template changes
* Catch templating- syntax- and logic issues
* Valuable for refactoring and development tasks
</div>

<div class="fragment">

### Pro
* Visibility → "Execution plan" providing in Pull request
* Verification → less failed deployments in the cluster
* Faster feedback cycle
* Enabling reviewers + detailed audit in Pull request
</div>

<div class="fragment">

### Con
* Initial effort for setup in CI + cluster integration
</div>

<div class="fragment">

"Once you have worked with diff previews, you won't want to miss the added security." 😀
</div>
</div>
---

# Questions?

<div style="display: flex; align-items: center; gap: 50px;" data-markdown>

  <div style="flex: 1;">

  #### Let's connect

  <img src="assets/ch5_linkedin_qr.png" style="max-height: 300px; width: auto; object-fit: contain;">
  </div>

  <div style="flex: 1;">

  #### I want to try a demo

  <img src="assets/ch5_argocd_diff_preview_demo.png" style="max-height: 300px; width: auto; object-fit: contain;">
  </div>
</div>
