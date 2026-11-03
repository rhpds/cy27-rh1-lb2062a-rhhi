#!/bin/sh
set -e
echo "Validating module-04" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:fips" ||
  fail_validation - <<'EOF'
Image `rhhi-demo:fips` was not found.

Review **“Build the FIPS Image”**, then validate again.
EOF

echo "PASS: module-04 validation complete" >> /tmp/progress.log
