#!/bin/sh
set -e
echo "Validating module-05" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-curl:local-ca" ||
  fail_validation "rhhi-curl:local-ca image not found. Build the curl image with the local CA before validating."

runuser -l rhel -c "test -f ~/webserver/root.crt" ||
  fail_validation "~/webserver/root.crt not found. Install the reverse proxy CA certificate before validating."

echo "PASS: module-05 validation complete" >> /tmp/progress.log
