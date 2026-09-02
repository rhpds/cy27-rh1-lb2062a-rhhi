# Module 02 — Hardened Image Variants (Distroless and Variants)

### Brief Overview

This module introduces the Red Hat Hardened Image variants available for Python: the default distroless image (`hi/python:3.14`) and the builder variant (`hi/python:3.14-builder`). Participants attempt to build the Flask application directly on the distroless image, observe the build failure caused by the missing shell, then switch to the builder variant and succeed. The module closes by comparing image sizes across UBI, distroless (where buildable), and builder variants — establishing that the builder variant is a build-time tool, not a production base.

### Audience and Time

- **Persona:** Developers or platform engineers who completed module 01 and have a UBI baseline as reference
- **Prerequisites for this module:** Module 01 complete; basic familiarity with Containerfile syntax (FROM, RUN, COPY, CMD)
- **Duration:** 25 minutes

### Learning Objectives

- Build a container image using the RHHI distroless Python variant and analyze the resulting build failure
- Build a container image using the RHHI builder Python variant and verify the application runs
- Analyze the trade-offs between the default distroless (production) and builder (build-time) RHHI variants by comparing image sizes and available tooling

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | RHHI Variant Overview | 5 min |
| 2 | Attempt Distroless Build and Observe Failure | 7 min |
| 3 | Switch to Builder Variant and Build Successfully | 8 min |
| 4 | Compare Image Sizes Across Variants | 5 min |

### Detailed Steps

1. Read the overview: explain the RHHI variant naming scheme — default (distroless), `-builder`, `-fips`, `-fips-builder` — and when each is used.
2. Run `cat ~/flask/Containerfile.hi` to examine the Containerfile targeting `hi/python:3.14` (distroless).
3. Attempt to build: `podman build -t rhhi-demo:distroless -f ~/flask/Containerfile.hi ~/flask/`.
4. Observe the build failure — the distroless image has no shell, so any `RUN` instruction that invokes `/bin/sh` or `pip` directly fails.
5. Read the error message carefully; identify that the missing shell is the cause.
6. Edit `~/flask/Containerfile.hi` with `vi` (or use a pre-staged `Containerfile.hi-builder`) to replace the `FROM` line with `hi/python:3.14-builder`.
7. Build the builder-based image: `podman build -t rhhi-demo:builder -f ~/flask/Containerfile.hi ~/flask/`.
8. Confirm the build succeeds.
9. Run the builder image: `podman run -d --name demo-builder -p 8080:8080 rhhi-demo:builder`.
10. Confirm the app responds in the browser.
11. Inspect available packages: `podman exec demo-builder rpm -qa | wc -l` — compare against the UBI baseline count.
12. Run `podman images` and compare sizes: UBI baseline vs. builder image.
13. Stop and remove the container: `podman stop demo-builder && podman rm demo-builder`.
14. Summarize: the builder variant works for single-stage builds but carries build tooling not needed at runtime; the production pattern (multi-stage builds) is covered in module 03.

### Key Takeaways

- Distroless RHHI images contain no shell — `RUN` instructions using `/bin/sh` or shell-based commands fail at build time.
- The builder variant adds a shell and build tooling and is designed for the build stage only, not production deployment.
- Even the builder variant may be smaller than UBI in some cases, but it is not the production target.
- The solution to running a distroless image in production is the multi-stage build pattern covered in module 03.

### Infrastructure Notes

- `Containerfile.hi` (targeting distroless) and `Containerfile.hi-builder` (targeting builder) must both be pre-staged in `~/flask/`.
- `hi/python:3.14` and `hi/python:3.14-builder` must be pullable from `registry.access.redhat.com`.
