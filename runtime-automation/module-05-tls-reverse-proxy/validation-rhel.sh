#!/bin/sh
set -e
echo "Validating module-05" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-curl:local-ca" ||
  fail_validation - <<'EOF'
**Validation incomplete:** Image `rhhi-curl:local-ca` was not found.

Review **“Build custom curl with CA bundle”** in Module 5, then validate again.
EOF

runuser -l rhel -c "test -f ~/webserver/root.crt" ||
  fail_validation - <<'EOF'
**Validation incomplete:** File `~/webserver/root.crt` was not found.

Review **“Extract the CA Certificate”** in Module 5, then validate again.
EOF

echo "PASS: module-05 validation complete" >> /tmp/progress.log
