#!/bin/sh
echo "Setup module-04" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
podman stop rhhi-flask rhhi-caddy rhhi-hardened rhhi-builder rhhi-fips rhhi-ubi 2>/dev/null || true
podman rm rhhi-flask rhhi-caddy rhhi-hardened rhhi-builder rhhi-fips rhhi-ubi 2>/dev/null || true
podman pod rm rhhi-pod 2>/dev/null || true
RHEL_EOF

echo "module-04 setup complete" >> /tmp/progress.log
