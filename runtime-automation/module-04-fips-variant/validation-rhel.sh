#!/bin/sh
set -e
echo "Validating module-04" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:fips" || {
  echo "FAIL: rhhi-demo:fips image not found" >&2
  exit 1
}

echo "PASS: module-04 validation complete" >> /tmp/progress.log
