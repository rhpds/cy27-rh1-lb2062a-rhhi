#!/bin/sh
set -e
echo "Validating module-01" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:ubi" || {
  echo "FAIL: rhhi-demo:ubi image not found" >&2
  exit 1
}

echo "PASS: rhhi-demo:ubi image exists" >> /tmp/progress.log
