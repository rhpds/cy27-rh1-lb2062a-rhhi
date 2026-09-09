#!/bin/sh
set -e
echo "Solving module-03: Multi-Stage Builds" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
set -e

podman build -t rhhi-demo:hardened -f ~/flask/Containerfile.hardened ~/flask

cat > ~/flask/Containerfile.debug << 'EOF'
FROM registry.access.redhat.com/hi/core-runtime:latest-builder
USER root
RUN dnf -y install busybox && dnf clean all
USER 65532
CMD ["/bin/bash"]
EOF

podman build -t rhhi-debug -f ~/flask/Containerfile.debug ~/flask
RHEL_EOF

echo "module-03 solve complete" >> /tmp/progress.log
