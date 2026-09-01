# Module 01 — Introduction to Red Hat Hardened Images / UBI Baseline

### Brief Overview

This module introduces the Red Hat Hardened Images lab and establishes a UBI baseline for comparison across all subsequent modules. Participants examine a pre-staged Flask demo application (`rhhi-demo`) and its UBI-based Containerfile, build and run the container using Podman, then inspect the resulting image's size and installed package count. These baseline metrics serve as the reference point against which every hardened image variant is measured throughout the lab.

### Audience and Time

- **Persona:** Developers or platform engineers new to RHHI; assumes basic Linux CLI and conceptual container knowledge
- **Prerequisites for this module:** None (first module); Podman and `~/flask/` directory pre-staged by provisioning automation
- **Duration:** 15 minutes

### Learning Objectives

- Build a container image from a UBI-based Containerfile and run it with Podman
- Observe UBI image size and installed package count as a measurable baseline for later comparison
- Explore the rhhi-demo Flask application to confirm it is serving responses correctly

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Introduction and Tour of ~/flask/ | 3 min |
| 2 | Examine the UBI Containerfile | 4 min |
| 3 | Build and Run the UBI Container | 5 min |
| 4 | Record Baseline Metrics | 3 min |

### Detailed Steps

1. Open a terminal via the Wetty browser tab.
2. Navigate to `~/flask/` and run `ls` to list the pre-staged application files (Containerfiles and Flask source).
3. Run `cat ~/flask/Containerfile.ubi` to read the UBI-based image definition.
4. Identify the base image (`ubi10/ubi`), the Flask dependency installation step (`pip install`), and the application entry point.
5. Build the UBI container image: `podman build -t rhhi-demo:ubi -f ~/flask/Containerfile.ubi ~/flask/`.
6. Run the container in the background: `podman run -d --name demo-ubi -p 8080:8080 rhhi-demo:ubi`.
7. Open a browser tab to the lab URL (`http://{guid}.{domain}:8080`) and confirm the Flask app returns a response.
8. Record the installed package count: `podman exec demo-ubi rpm -qa | wc -l`.
9. Record the image size: `podman images rhhi-demo:ubi --format "{{.Size}}"`.
10. Stop and remove the container: `podman stop demo-ubi && podman rm demo-ubi`.
11. Note both metrics — image size and package count — as the UBI baseline for comparison in later modules.

### Key Takeaways

- UBI provides a familiar RPM-based environment but includes packages that may not be required in production workloads.
- Image size and installed package count are concrete, measurable indicators of container attack surface.
- The `rhhi-demo` Flask application serves as the consistent workload throughout all five modules; the container runtime is the only thing that changes.

### Infrastructure Notes

- `~/flask/` must be pre-staged by provisioning automation with all Containerfiles and the Flask application source.
- Port 8080 must be accessible from the learner's browser via the per-student `{guid}.{domain}` URL.
- The `ubi10/ubi` base image must be pullable from `registry.access.redhat.com` at build time.
