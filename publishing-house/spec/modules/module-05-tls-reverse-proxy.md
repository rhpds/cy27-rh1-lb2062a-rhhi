# Module 05 — TLS Reverse Proxy with Hardened Images

### Brief Overview

This module demonstrates a realistic multi-container deployment pattern using a Podman pod to co-locate the hardened Flask application and a Caddy TLS reverse proxy from the RHHI catalog. Participants create the pod, start both containers inside it, and immediately encounter a TLS certificate trust failure from Caddy's self-generated internal CA. They extract the root certificate, inspect it with OpenSSL, then build a custom curl image (derived from RHHI `curl:latest-builder` via multi-stage) with the CA bundle embedded — resolving the trust failure and verifying successful HTTPS access. The module consolidates skills from every prior module into a production-representative deployment.

### Audience and Time

- **Persona:** Developers or platform engineers deploying multi-container workloads with TLS termination using only RHHI-sourced images
- **Prerequisites for this module:** Modules 01-04 complete; familiarity with multi-stage builds and the RHHI image catalog; `~/webserver/` pre-staged by automation
- **Duration:** 30 minutes

### Learning Objectives

- Deploy a Podman pod containing a hardened Flask application container and a Caddy TLS reverse proxy container
- Troubleshoot a TLS certificate trust failure caused by an internal CA and extract the root certificate for inspection
- Build a custom RHHI curl image with an embedded CA trust bundle to verify HTTPS connectivity through the TLS proxy

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Create a Podman Pod | 5 min |
| 2 | Start Application and Caddy Proxy Containers | 7 min |
| 3 | Observe TLS Trust Failure and Extract CA Certificate | 5 min |
| 4 | Build Custom curl with Embedded CA Bundle | 8 min |
| 5 | Verify HTTPS and Wrap Up | 5 min |

### Detailed Steps

1. Review the module setup: `~/webserver/` contains the Caddy configuration file and a self-generated internal CA certificate used by Caddy for TLS termination.
2. Run `cat ~/webserver/Caddyfile` to examine the Caddy configuration (TLS termination on port 8443, reverse proxy to the Flask app on port 8080 within the pod).
3. Create a Podman pod: `podman pod create --name rhhi-pod -p 8080:8080 -p 8443:8443`.
4. Start the Flask application container inside the pod: `podman run -d --pod rhhi-pod --name demo-app rhhi-demo:prod`.
5. Start the Caddy container inside the pod: `podman run -d --pod rhhi-pod --name demo-caddy -v ~/webserver:/etc/caddy:Z caddy:latest`.
6. Confirm both containers are running: `podman ps`.
7. Attempt HTTPS access: `podman run --rm curl:latest curl https://localhost:8443`. Observe the TLS verification failure — the internal CA is not trusted.
8. Attempt with `-k` flag to confirm the application is reachable despite the cert error: `podman run --rm curl:latest curl -k https://localhost:8443`.
9. Copy the Caddy CA certificate out of the running container: `podman cp demo-caddy:/data/caddy/pki/authorities/local/root.crt ~/root.crt`.
10. Inspect the certificate: `openssl x509 -in ~/root.crt -noout -text`. Note the subject, issuer (self-signed), and validity period.
11. Examine the custom curl Containerfile: `cat ~/flask/Containerfile.curl`. It uses `curl:latest-builder` as the build stage to access CA trust tooling, embeds `~/root.crt` into the trust store, then copies the curl binary into a `curl:latest` final stage.
12. Build the custom curl image: `podman build -t rhhi-curl:trusted -f ~/flask/Containerfile.curl --build-arg CA_CERT=root.crt ~/`.
13. Run the custom curl container targeting the Caddy proxy: `podman run --rm --network=container:demo-caddy rhhi-curl:trusted curl https://localhost:8443`.
14. Observe successful HTTPS response — the embedded CA bundle allows chain verification.
15. Stop and remove the pod: `podman pod stop rhhi-pod && podman pod rm rhhi-pod`.
16. Wrap up: summarize the complete pattern — Podman pod, hardened app image, hardened proxy image, hardened tool image with embedded trust — as a production-ready deployment approach using only RHHI-sourced images.

### Key Takeaways

- Podman pods allow multiple containers to share a network namespace, enabling sidecar and reverse proxy patterns without Kubernetes.
- RHHI provides catalog images for infrastructure components (Caddy, curl) as well as application runtimes, enabling a fully hardened stack.
- TLS trust failures in minimal images are resolved by embedding CA bundles at image build time using multi-stage builds — not by runtime shell commands.
- The multi-stage pattern with `curl:latest-builder` mirrors the pattern from module 03: build-time tooling in the builder stage, minimal runtime in the final stage.
- Combining a Podman pod, hardened images, and embedded trust anchors constitutes a production-representative deployment pattern.

### Infrastructure Notes

- `~/webserver/` must be pre-staged with the Caddy configuration file and a self-generated CA certificate; Caddy will regenerate TLS material on first start if not provided.
- Ports 8080 and 8443 must be accessible from the learner's browser for end-to-end verification.
- `caddy:latest`, `curl:latest`, and `curl:latest-builder` must be pullable from `registry.access.redhat.com`.
- `Containerfile.curl` must be pre-staged in `~/flask/` or an equivalent accessible location.
- The `rhhi-demo:prod` image from module 03 must still be present on the learner host (do not prune between modules).
