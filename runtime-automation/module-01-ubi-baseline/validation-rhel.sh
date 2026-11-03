#!/bin/sh
set -e
echo "Validating module-01" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:ubi" ||
  fail_validation - <<'EOF'
The pre-built image `rhhi-demo:ubi` was not found.

This image should be available when the lab starts. Review **“Run the Application”**, then validate again.
EOF

echo "PASS: rhhi-demo:ubi image exists" >> /tmp/progress.log
