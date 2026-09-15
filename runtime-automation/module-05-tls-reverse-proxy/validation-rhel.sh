#!/bin/sh
set -e
echo "Validating module-05" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-curl:local-ca" || {
  echo "FAIL: rhhi-curl:local-ca image not found" >&2
  exit 1
}

runuser -l rhel -c "test -f ~/webserver/root.crt" || {
  echo "FAIL: ~/webserver/root.crt not found" >&2
  exit 1
}

echo "PASS: module-05 validation complete" >> /tmp/progress.log
