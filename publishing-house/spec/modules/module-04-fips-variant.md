# Module 04 — Customized Security Images (FIPS Variant)

### Brief Overview

This module introduces the RHHI FIPS image variant (`hi/python:3.14-fips`), which enforces FIPS 140-3 cryptographic policy via the OpenSSL FIPS provider embedded in the image — independently of whether the RHEL host is running in FIPS mode. Participants check the host FIPS status, build and run a FIPS-variant Flask container, and observe in the application UI that MD5 is blocked while SHA-256 and SHA-512 succeed. They then compare the same test against the non-FIPS production image from module 03 to confirm enforcement is container-level, not host-level. No application code changes are required.

### Audience and Time

- **Persona:** Developers or platform engineers deploying workloads in regulated environments (FedRAMP, DoD, financial sector) where FIPS 140-3 cryptographic compliance is required
- **Prerequisites for this module:** Modules 01-03 complete; familiarity with building and running RHHI images from prior modules
- **Duration:** 20 minutes

### Learning Objectives

- Build a container image using the RHHI FIPS Python variant without modifying application source code
- Verify FIPS 140-3 cryptographic policy enforcement by observing which hash algorithms are blocked and which succeed in the running container
- Analyze the difference between host-level FIPS mode and container-level FIPS enforcement using the RHHI FIPS variant

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Introduction and Host FIPS Status | 4 min |
| 2 | Build and Run the FIPS Image | 6 min |
| 3 | Verify FIPS Enforcement in the Application | 6 min |
| 4 | Compare FIPS vs Non-FIPS Behavior | 4 min |

### Detailed Steps

1. Introduce the FIPS variant: the `-fips` tag on RHHI images includes the OpenSSL FIPS provider configured and enabled, enforcing FIPS 140-3 at the container level.
2. Check host FIPS mode: `cat /proc/sys/crypto/fips_enabled`. Note the value (likely `0` on this lab host — host FIPS mode is not required for container-level enforcement).
3. Examine the FIPS Containerfile: `cat ~/flask/Containerfile.hi-fips`. Note the only difference from the module 03 multi-stage Containerfile is the base image tag `hi/python:3.14-fips`.
4. Run `diff ~/flask/Containerfile.hi-multistage ~/flask/Containerfile.hi-fips` to confirm the base image is the sole change — no application code modification is needed.
5. Build the FIPS image: `podman build -t rhhi-demo:fips -f ~/flask/Containerfile.hi-fips ~/flask/`.
6. Run the FIPS container: `podman run -d --name demo-fips -p 8080:8080 rhhi-demo:fips`.
7. Open the application UI in the browser and navigate to the hash algorithm test page.
8. Trigger MD5 hashing — observe the error or failure response (MD5 is not FIPS-compliant and is blocked by the OpenSSL FIPS provider).
9. Trigger SHA-256 hashing — observe success (SHA-256 is FIPS-compliant).
10. Trigger SHA-512 hashing — observe success (SHA-512 is FIPS-compliant).
11. Stop the FIPS container: `podman stop demo-fips && podman rm demo-fips`.
12. Start the non-FIPS production image from module 03: `podman run -d --name demo-prod -p 8080:8080 rhhi-demo:prod`.
13. Repeat the MD5 test in the browser — observe that MD5 succeeds in the non-FIPS image.
14. Stop the non-FIPS container: `podman stop demo-prod && podman rm demo-prod`.
15. Summarize: the FIPS variant enforces cryptographic policy at the container level; switching base image tag is the only required change.

### Key Takeaways

- The RHHI FIPS variant enforces FIPS 140-3 cryptographic policy via the OpenSSL FIPS provider embedded in the image, regardless of host FIPS mode.
- No application code changes are required — only the base image tag changes from `hi/python:3.14` to `hi/python:3.14-fips`.
- MD5 is blocked under FIPS enforcement; SHA-256 and SHA-512 are compliant and allowed.
- Container-level FIPS enforcement enables compliance in mixed environments where the host OS may not be in FIPS mode.

### Infrastructure Notes

- `Containerfile.hi-fips` must be pre-staged in `~/flask/`; it should be a copy of the multi-stage Containerfile from module 03 with the final stage base image changed to `hi/python:3.14-fips`.
- The Flask application must expose hash algorithm test endpoints (MD5, SHA-256, SHA-512) accessible from the learner browser.
- `hi/python:3.14-fips` must be pullable from `registry.access.redhat.com`.
- The `rhhi-demo:prod` image built in module 03 should still be present on the learner's host for the comparison step; do not prune between modules.
