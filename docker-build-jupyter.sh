#!/usr/bin/env bash
set -euo pipefail

docker build --squash . -t jupyter:bionic > /tmp/jupyter-docker-build.log 2>&1
