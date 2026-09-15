#!/bin/sh
set -e
echo "Validating module-03" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:hardened" || {
  echo "FAIL: rhhi-demo:hardened image not found" >&2
  exit 1
}

runuser -l rhel -c "podman image exists rhhi-debug" || {
  echo "FAIL: rhhi-debug image not found" >&2
  exit 1
}

runuser -l rhel -c "test -f ~/flask/Containerfile.debug" || {
  echo "FAIL: ~/flask/Containerfile.debug not found" >&2
  exit 1
}

echo "PASS: module-03 validation complete" >> /tmp/progress.log
