#!/bin/sh
set -e
echo "Solving module-04: FIPS Variant" >> /tmp/progress.log

runuser -l rhel -c "podman build -t rhhi-demo:fips -f ~/flask/Containerfile.fips ~/flask"

echo "module-04 solve complete" >> /tmp/progress.log
