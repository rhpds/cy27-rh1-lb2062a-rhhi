#!/bin/sh
set -e
echo "Validating module-04" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:fips" ||
  fail_validation "rhhi-demo:fips image not found. Build the FIPS variant before validating."

echo "PASS: module-04 validation complete" >> /tmp/progress.log
