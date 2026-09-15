#!/bin/sh
set -e
echo "Solving module-02: Hardened Variants" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
set -e

cat > ~/flask/Containerfile.hi << 'EOF'
FROM registry.access.redhat.com/hi/python:3.14-builder
USER root
RUN pip install flask
WORKDIR /app
COPY --chown=65532 app.py .
USER ${CONTAINER_DEFAULT_USER}
EXPOSE 8080
ENV RHHI_VARIANT=builder
STOPSIGNAL SIGINT
ENTRYPOINT ["python", "./app.py"]
EOF

podman build -t rhhi-demo:builder -f ~/flask/Containerfile.hi ~/flask
RHEL_EOF

echo "module-02 solve complete" >> /tmp/progress.log
