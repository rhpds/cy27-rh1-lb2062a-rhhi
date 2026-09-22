# Module 05 — TLS Reverse Proxy with Hardened Images

### Brief Overview

This module demonstrates a realistic multi-container deployment pattern using a Podman pod to co-locate the hardened Flask application and a Caddy TLS reverse proxy from the RHHI catalog. Participants create the pod, start both containers inside it, and immediately encounter a TLS certificate trust failure from Caddy's internal CA. They extract the root certificate, inspect it with OpenSSL, then create and build a custom curl image (derived from RHHI `curl:latest-builder` via multi-stage) with the CA bundle embedded — resolving the trust failure and verifying successful HTTPS access. The module consolidates skills from every prior module into a production-representative deployment.

### Audience and Time

- **Persona:** Developers or platform engineers deploying multi-container workloads with TLS termination using only RHHI-sourced images
- **Prerequisites for this module:** Modules 01-04 complete; familiarity with multi-stage builds and the RHHI image catalog; `~/webserver/` pre-staged by automation with a Caddyfile; `rhhi-demo:hardened` image present from module 03
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

1. Review the module setup: `~/webserver/` contains the Caddy configuration file (`Caddyfile`) pre-staged by automation.
2. Run `cat ~/webserver/Caddyfile` to examine the Caddy configuration (TLS termination on the external lab hostname, reverse proxy to Flask on `localhost:8080` within the pod).
3. Create a Podman pod exposing only the TLS port: `podman pod create --name rhhi-pod -p 8443:8443`.
4. Start the Flask application container inside the pod: `podman run -d --pod rhhi-pod --name rhhi-flask rhhi-demo:hardened`.
5. Start the Caddy container inside the pod, mounting only the Caddyfile: `podman run -d --pod rhhi-pod --name rhhi-caddy -v ~/webserver/Caddyfile:/etc/caddy/Caddyfile:Z <registry>/caddy:latest`.
6. Navigate to `https://caddy-{guid}.{domain}/` in the browser and observe the certificate warning — the internal CA is not trusted.
7. From the terminal, attempt HTTPS access with `curl https://caddy-{guid}.{domain}/` and observe the SSL verification failure; note that `-k` bypasses verification but defeats TLS entirely — the correct fix is to embed the CA.
8. Copy the Caddy CA certificate out of the running container: `podman cp rhhi-caddy:/data/caddy/pki/authorities/local/root.crt ~/webserver`.
9. Inspect the certificate: `openssl x509 -in ~/webserver/root.crt -noout -subject -issuer -purpose -dates`. Note the Caddy Local Authority subject/issuer (self-signed) and CA-only purpose flags.
10. Create `~/webserver/Containerfile.pem` inline using a heredoc: multi-stage build using `curl:latest-builder` to run `trust anchor` on the extracted cert, then copy only the extracted PKI trust store into the final `curl:latest` stage.
11. Build the custom curl image: `podman build -t rhhi-curl:local-ca -f ~/webserver/Containerfile.pem ~/webserver`.
12. Run the custom curl container targeting the Caddy proxy: `podman run --rm rhhi-curl:local-ca -s https://caddy-{guid}.{domain}/crypto-demo`.
13. Observe successful HTTPS response with hash table output — the embedded CA bundle allows chain verification.
14. Wrap up: summarize the complete pattern — Podman pod, hardened app image, hardened proxy image, hardened tool image with embedded trust — as a production-ready deployment approach using only RHHI-sourced images.

### Key Takeaways

- Podman pods allow multiple containers to share a network namespace, enabling sidecar and reverse proxy patterns without Kubernetes.
- RHHI provides catalog images for infrastructure components (Caddy, curl) as well as application runtimes, enabling a fully hardened stack.
- TLS trust failures in minimal images are resolved by embedding CA bundles at image build time using multi-stage builds — not by runtime shell commands.
- The multi-stage pattern with `curl:latest-builder` mirrors the pattern from module 03: build-time tooling in the builder stage, minimal runtime in the final stage.
- Combining a Podman pod, hardened images, and embedded trust anchors constitutes a production-representative deployment pattern.

### Infrastructure Notes

- `~/webserver/` must be pre-staged with the Caddyfile using the correct external hostname for the learner's `{guid}.{domain}`.
- Port 8443 must be accessible from the learner's browser for end-to-end verification.
- `caddy:latest`, `curl:latest`, and `curl:latest-builder` must be pullable from the RHHI registry at build/run time.
- `rhhi-demo:hardened` from module 03 must still be present on the learner host (do not prune between modules).
