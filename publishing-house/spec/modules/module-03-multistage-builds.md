# Module 03 — Multi-Stage Builds and Operating Hardened Images

### Brief Overview

This module introduces the multi-stage build pattern as the production-ready solution for deploying applications on distroless RHHI images. Participants write and build a multi-stage Containerfile that installs dependencies in a builder stage and copies only the application artifacts into a minimal distroless final image. They then confront the operational challenge of a running container with no shell: direct `exec` fails, so they build a debug sidecar container using `core-runtime:latest-builder` with busybox, attach it to the running app via shared PID and network namespaces, and use it to inspect live processes and network state. This is the most technically demanding module in the lab.

### Audience and Time

- **Persona:** Developers or platform engineers who completed modules 01 and 02 and are comfortable with basic Containerfile syntax and the reason distroless images have no shell
- **Prerequisites for this module:** Modules 01 and 02 complete; understanding of why distroless images cannot use `RUN` shell commands
- **Duration:** 30 minutes

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

1. Examine the multi-stage Containerfile: `cat ~/flask/Containerfile.hardened`. Identify stage 1 (`FROM hi/python:3.14-builder AS builder`) where `pip install` runs, and stage 2 (`FROM hi/python:3.14`) where only the application and its installed packages are copied.
2. Build the production image: `podman build -t rhhi-demo:hardened -f ~/flask/Containerfile.hardened ~/flask/`.
3. Run the production container: `podman run -d --rm --name rhhi-hardened -p 8080:8080 rhhi-demo:hardened`.
4. Confirm the app responds in the browser.
5. Run `podman images rhhi-demo` to compare sizes: UBI baseline, builder image (module 02), and production multi-stage image. Note the reduction.
6. Attempt to run `rpm` via `--entrypoint`: `podman run --rm --entrypoint rpm rhhi-demo:hardened -qa`. Observe the OCI runtime error — `rpm` is not present in the distroless image.
7. Acknowledge that the only live inspection path is a sidecar container sharing namespaces with the running container.
8. Run a one-shot sidecar using the registry `core-runtime:latest-builder` image directly — pass `--pid container:rhhi-hardened`, `--network container:rhhi-hardened`, `--security-opt label=disable`, `--user 0`, and `rpm --root=/proc/1/root -qa | wc -l` — to count the application image's installed packages via `/proc`.
9. Create `~/flask/Containerfile.debug` via heredoc: start `FROM core-runtime:latest-builder`, install `busybox`, set `CMD ["/bin/bash"]`.
10. Build the interactive debug sidecar: `podman build -t rhhi-debug -f ~/flask/Containerfile.debug ~/flask/`.
11. Attach the sidecar interactively: `podman run --rm -it --pid container:rhhi-hardened --network container:rhhi-hardened --security-opt label=disable --user 0 rhhi-debug bash`.
12. Inside the sidecar: run `ls /app` and observe the "No such file or directory" error — the sidecar has its own filesystem.
13. Access the target's filesystem via `/proc`: `ls -l /proc/1/root/app` and `head /proc/1/root/app/app.py` to confirm access to the running application's files.
14. Run `busybox ps` — observe the Flask application as PID 1 in the shared process namespace.
15. Run `busybox netstat -tlnp` — observe port 8080 listening in the shared network namespace.
16. Run `curl -s -o /dev/null -w "HTTP %{http_code}\n" localhost:8080/crypto-demo` — confirm HTTP 200 via the shared network namespace.
17. Exit the sidecar shell; confirm the application container is still running with `podman ps`.
18. Stop the production container: `podman stop rhhi-hardened`.

### Key Takeaways

- Multi-stage builds separate the build environment (builder variant with shell and tools) from the production runtime (distroless), keeping the final image minimal.
- The production multi-stage image is smaller than both UBI and the builder image due to the absence of build tooling and shell.
- Distroless production images cannot be exec'd into directly — they contain no shell.
- Debug sidecars with `--pid=container:<name>` and `--network=container:<name>` give full runtime visibility into a running shellless container.
- `core-runtime:latest-builder` is the foundation for building custom debug sidecar images with tools like busybox.

### Infrastructure Notes

- `Containerfile.hardened` is written by the participant in a prior module and must be present in `~/flask/`; `Containerfile.debug` is created by the participant during this module via heredoc.
- `core-runtime:latest-builder` and `busybox` must be accessible at sidecar build time (pullable from registry or cached).
