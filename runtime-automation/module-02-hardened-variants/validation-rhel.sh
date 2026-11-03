#!/bin/sh
set -e
echo "Validating module-02" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:builder" ||
  fail_validation "rhhi-demo:builder image not found. Build the builder variant before validating."

runuser -l rhel -c "grep -q 'python:3.14-builder' ~/flask/Containerfile.hi" ||
  fail_validation "Containerfile.hi does not use the python:3.14-builder variant. Update the builder stage and rebuild the image."

echo "PASS: module-02 validation complete" >> /tmp/progress.log
