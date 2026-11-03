#!/bin/sh
set -e
echo "Validating module-01" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:ubi" ||
  fail_validation "rhhi-demo:ubi image not found. Build the UBI baseline image before validating."

echo "PASS: rhhi-demo:ubi image exists" >> /tmp/progress.log
