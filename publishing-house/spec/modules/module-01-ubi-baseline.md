# Module 01 — Introduction to Red Hat Hardened Images / UBI Baseline

### Brief Overview

This module introduces the Red Hat Hardened Images lab and establishes a UBI baseline for comparison across all subsequent modules. Participants examine a pre-staged Flask demo application (`rhhi-demo`) and its UBI-based Containerfile, run the pre-built UBI container using Podman, then inspect the installed package count. These baseline metrics serve as the reference point against which every hardened image variant is measured throughout the lab.

### Audience and Time

- **Persona:** Developers or platform engineers new to RHHI; assumes basic Linux CLI and conceptual container knowledge
- **Prerequisites for this module:** None (first module); Podman and `~/flask/` directory pre-staged by provisioning automation; `rhhi-demo:ubi` image pre-built
- **Duration:** 15 minutes

### Learning Objectives

- Examine a UBI-based Containerfile and understand the conventional approach to containerizing a Python application
- Run the pre-built UBI container and confirm the Flask application is serving responses correctly
- Observe the UBI installed package count as a measurable baseline for later comparison

### Lab Structure

| Section | Title | Duration |
|---------|-------|----------|
| 1 | Introduction and Tour of ~/flask/ | 3 min |
| 2 | Examine the UBI Containerfile | 4 min |
| 3 | Run the UBI Container | 5 min |
| 4 | Record Baseline Package Count | 3 min |

### Detailed Steps

1. Open a terminal via the Wetty browser tab.
2. Navigate to `~/flask/` and run `ls` to list the pre-staged application files (Containerfiles and Flask source).
3. Run `cat ~/flask/Containerfile.ubi` to read the UBI-based image definition.
4. Identify the base image (`ubi10/ubi`), the Flask dependency installation step (`pip install`), and the application entry point.
5. Run the pre-built UBI container in the background: `podman run -d --rm --name rhhi-ubi -p 8080:8080 rhhi-demo:ubi`.
6. Open a browser tab to `http://flask-{guid}.{domain}/crypto-demo` and confirm the Flask app returns a response; optionally enter text and click Hash to observe all three algorithm outputs.
7. Record the installed package count: `podman exec -it rhhi-ubi rpm -qa | wc -l`.
8. Note the package count as the UBI baseline for comparison in later modules.
9. Stop the container: `podman stop rhhi-ubi` (the `--rm` flag removes it automatically).

### Key Takeaways

- UBI provides a familiar RPM-based environment but includes packages that may not be required in production workloads.
- Installed package count is a concrete, measurable indicator of container attack surface.
- The `rhhi-demo` Flask application serves as the consistent workload throughout all five modules; the container runtime is the only thing that changes.

### Infrastructure Notes

- `~/flask/` must be pre-staged by provisioning automation with all Containerfiles and the Flask application source.
- `rhhi-demo:ubi` must be pre-built and available on the learner host at lab start.
- The Flask application URL uses the pattern `http://flask-{guid}.{domain}/crypto-demo`.
- The `ubi10/ubi` base image must have been pullable from `registry.access.redhat.com` at image build time.
