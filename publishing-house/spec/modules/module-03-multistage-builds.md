# Module 03 — Multi-Stage Builds and Operating Hardened Images

### Brief Overview

This module introduces the multi-stage build pattern as the production-ready solution for deploying applications on distroless RHHI images. Participants write and build a multi-stage Containerfile that installs dependencies in a builder stage and copies only the application artifacts into a minimal distroless final image. They then confront the operational challenge of a running container with no shell: direct `exec` fails, so they build a debug sidecar container using `core-runtime:latest-builder` with busybox, attach it to the running app via shared PID and network namespaces, and use it to inspect live processes and network state. This is the most technically demanding module in the lab.

### Audience and Time

- **Persona:** Developers or platform engineers who completed modules 01 and 02 and are comfortable with basic Containerfile syntax and the reason distroless images have no shell
- **Prerequisites for this module:** Modules 01 and 02 complete; understanding of why distroless images cannot use `RUN` shell commands
- **Duration:** 40 minutes

### Learning Objectives

- Implement a multi-stage Containerfile that installs dependencies in a builder stage and copies application artifacts into a distroless production image
- Build and run the production-grade multi-stage image and verify it is smaller than both the UBI and builder images
- Operate a running distroless container by building a debug sidecar with busybox and attaching it using shared PID and network namespaces

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | The Multi-Stage Build Pattern | 8 min |
| 2 | Build and Run the Production Image | 7 min |
| 3 | Compare All Image Sizes | 5 min |
| 4 | Attempt Direct Exec (Observe Failure) | 5 min |
| 5 | Build and Attach a Debug Sidecar | 15 min |

### Detailed Steps

1. Examine the multi-stage Containerfile: `cat ~/flask/Containerfile.hi-multistage`. Identify stage 1 (`FROM hi/python:3.14-builder AS builder`) where `pip install` runs, and stage 2 (`FROM hi/python:3.14`) where only the application and its installed packages are copied.
2. Build the production image: `podman build -t rhhi-demo:prod -f ~/flask/Containerfile.hi-multistage ~/flask/`.
3. Run the production container: `podman run -d --name demo-prod -p 8080:8080 rhhi-demo:prod`.
4. Confirm the app responds in the browser.
5. Run `podman images` to compare sizes: UBI baseline, builder image (module 02), and production multi-stage image. Note the reduction.
6. Attempt to exec into the production container: `podman exec -it demo-prod /bin/bash`. Observe the failure — no shell present in the distroless image.
7. Attempt `podman exec -it demo-prod /bin/sh`. Observe the same failure.
8. Acknowledge that the only live inspection path is a sidecar container sharing namespaces with the running container.
9. Examine the sidecar Containerfile: `cat ~/flask/Containerfile.sidecar`. It starts `FROM core-runtime:latest-builder` and installs busybox.
10. Build the sidecar image: `podman build -t debug-sidecar -f ~/flask/Containerfile.sidecar ~/flask/`.
11. Launch the sidecar container with shared PID and network namespaces: `podman run -it --pid=container:demo-prod --network=container:demo-prod debug-sidecar`.
12. Inside the sidecar shell, run `busybox ps` — observe the Flask application process visible in the shared PID namespace.
13. Run `busybox netstat -tlnp` (or `busybox ss -tlnp`) — observe port 8080 listening in the shared network namespace.
14. Run `rpm -qa | wc -l` inside the sidecar to inspect the core-runtime builder package count.
15. Exit the sidecar shell.
16. Stop and remove both containers: `podman stop demo-prod && podman rm demo-prod`.
17. Reflect: multi-stage builds deliver a minimal production image; debug sidecars with shared namespaces are the supported inspection pattern.

### Key Takeaways

- Multi-stage builds separate the build environment (builder variant with shell and tools) from the production runtime (distroless), keeping the final image minimal.
- The production multi-stage image is smaller than both UBI and the builder image due to the absence of build tooling and shell.
- Distroless production images cannot be exec'd into directly — they contain no shell.
- Debug sidecars with `--pid=container:<name>` and `--network=container:<name>` give full runtime visibility into a running shellless container.
- `core-runtime:latest-builder` is the foundation for building custom debug sidecar images with tools like busybox.

### Infrastructure Notes

- `Containerfile.hi-multistage` and `Containerfile.sidecar` must be pre-staged in `~/flask/`.
- `core-runtime:latest-builder` and `busybox` must be accessible at sidecar build time (pullable from registry or cached).
- Allocate extra instructor time for this module — it is 40 minutes and involves the most steps. Participants who fall behind on the sidecar build may need guidance on the `--pid` and `--network` flags.
