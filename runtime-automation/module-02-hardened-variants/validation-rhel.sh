#!/bin/sh
set -e
echo "Validating module-02" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:builder" || {
  echo "FAIL: rhhi-demo:builder image not found" >&2
  exit 1
}

runuser -l rhel -c "grep -q 'python:3.14-builder' ~/flask/Containerfile.hi" || {
  echo "FAIL: Containerfile.hi does not use the builder variant" >&2
  exit 1
}

echo "PASS: module-02 validation complete" >> /tmp/progress.log
