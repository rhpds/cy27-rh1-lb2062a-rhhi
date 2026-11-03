#!/bin/sh
set -e
echo "Validating module-03" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:hardened" ||
  fail_validation - <<'EOF'
Image `rhhi-demo:hardened` was not found.

Review **“The Multi-Stage Solution”**, then validate again.
EOF

runuser -l rhel -c "podman image exists rhhi-debug" ||
  fail_validation - <<'EOF'
Image `rhhi-debug` was not found.

Review **“Build a Debug Sidecar”**, then validate again.
EOF

runuser -l rhel -c "test -f ~/flask/Containerfile.debug" ||
  fail_validation - <<'EOF'
File `~/flask/Containerfile.debug` was not found.

Review **“Build a Debug Sidecar”**, then validate again.
EOF

echo "PASS: module-03 validation complete" >> /tmp/progress.log
