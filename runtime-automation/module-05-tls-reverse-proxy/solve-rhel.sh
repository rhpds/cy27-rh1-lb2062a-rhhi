#!/bin/sh
set -e
echo "Solving module-05: TLS Reverse Proxy" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
set -e

podman pod create --name rhhi-pod -p 8443:8443
podman run -d --pod rhhi-pod --name rhhi-flask rhhi-demo:hardened
podman run -d --pod rhhi-pod --name rhhi-caddy \
  -v ~/webserver/Caddyfile:/etc/caddy/Caddyfile:Z \
  registry.access.redhat.com/hi/caddy:latest

# Wait for Caddy to generate its internal CA certificate
for i in $(seq 1 30); do
  podman exec rhhi-caddy test -f /data/caddy/pki/authorities/local/root.crt 2>/dev/null && break
  sleep 2
done

podman cp rhhi-caddy:/data/caddy/pki/authorities/local/root.crt ~/webserver/

cat > ~/webserver/Containerfile.pem << 'EOF'
FROM registry.access.redhat.com/hi/curl:latest-builder AS builder
COPY root.crt /tmp/
USER root
RUN trust anchor /tmp/root.crt
USER ${CONTAINER_DEFAULT_USER}

FROM registry.access.redhat.com/hi/curl:latest
COPY --from=builder /etc/pki/ca-trust/extracted /etc/pki/ca-trust/extracted
EOF

podman build -t rhhi-curl:local-ca -f ~/webserver/Containerfile.pem ~/webserver

podman pod stop rhhi-pod
podman pod rm rhhi-pod
RHEL_EOF

echo "module-05 solve complete" >> /tmp/progress.log
