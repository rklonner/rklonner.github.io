#!/bin/sh
# Simple script to launch a local HTTP server for Reveal.js (for markdown loading)
PORT=8000
HERE=$(dirname "$0")
cd "$HERE"
echo "Serving Reveal.js from http://localhost:$PORT/index.html"
echo "Press Ctrl+C to exit."
python3 -m http.server $PORT
