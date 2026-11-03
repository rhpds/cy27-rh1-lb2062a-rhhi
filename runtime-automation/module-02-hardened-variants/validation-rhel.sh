#!/bin/sh
set -e
echo "Validating module-02" >> /tmp/progress.log

runuser -l rhel -c "podman image exists rhhi-demo:builder" ||
  fail_validation - <<'EOF'
**Validation incomplete:** Image `rhhi-demo:builder` was not found.

Review **“Switch to the Builder Variant”** in Module 2, then validate again.
EOF

runuser -l rhel -c "grep -q 'python:3.14-builder' ~/flask/Containerfile.hi" ||
  fail_validation - <<'EOF'
**Validation incomplete:** The expected `python:3.14-builder` reference was not found in `~/flask/Containerfile.hi`.

Review **“Switch to the Builder Variant”** in Module 2, then validate again.
EOF

echo "PASS: module-02 validation complete" >> /tmp/progress.log
