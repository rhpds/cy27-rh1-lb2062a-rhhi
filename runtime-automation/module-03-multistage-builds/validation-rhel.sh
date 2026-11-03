#!/bin/sh
set -e
echo "Validating module-03" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:hardened" ||
  fail_validation "rhhi-demo:hardened image not found. Build the hardened multi-stage image before validating."

runuser -l rhel -c "podman image exists rhhi-debug" ||
  fail_validation "rhhi-debug image not found. Build the debug image before validating."

runuser -l rhel -c "test -f ~/flask/Containerfile.debug" ||
  fail_validation "~/flask/Containerfile.debug not found. Create the debug Containerfile before validating."

echo "PASS: module-03 validation complete" >> /tmp/progress.log
