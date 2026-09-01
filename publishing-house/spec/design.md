# Red Hat Hardened Images

## Overview

This lab introduces Red Hat Hardened Images (RHHI), a catalog of minimized, security-hardened container images maintained by Red Hat as hardened alternatives to Universal Base Images. Participants work through a progression of container build patterns — from UBI baseline to distroless hardened images, multi-stage builds, FIPS-enforced cryptographic policy, and TLS reverse proxy deployment — using a pre-staged Flask application running on a RHEL host. By the end of the lab, participants will have built container images using multiple RHHI variants, compared security posture and footprint against UBI, operated a shellless distroless container using a debug sidecar, enforced FIPS 140-3 policy at the container level, and deployed a production-representative Podman pod with TLS termination backed by a custom trust bundle.

## Target Audience

- **Role:** Developers and platform engineers evaluating Red Hat Hardened Images as a UBI replacement for production containerized workloads
- **Experience level:** Intermediate
- **What they already know:** Basic Linux CLI usage; conceptual understanding of containers (images, registries, running containers); no prior Podman expertise or Kubernetes/OpenShift knowledge required
- **What they don't know:** RHHI image variants and their trade-offs; multi-stage Containerfile patterns; debugging containers without a shell; FIPS 140-3 container-level enforcement; Podman pod networking and TLS certificate trust

## Prerequisites

- Basic Linux command-line proficiency (navigating directories, reading files, running commands in a terminal)
- Conceptual familiarity with containers (what an image is, what a container does)
- Cannot be validated automatically — no automated prerequisite check is implemented

## Learning Objectives

1. Build container images using Red Hat Hardened Image distroless, builder, and FIPS variants and compare image sizes against a UBI baseline
2. Implement multi-stage builds to produce minimal, production-ready distroless container images
3. Operate a running distroless container by building and attaching a debug sidecar using shared PID and network namespaces
4. Verify FIPS 140-3 cryptographic policy enforcement by building and running the RHHI FIPS image variant and observing blocked and allowed cipher operations
5. Deploy a Podman pod running a hardened application and a Caddy TLS reverse proxy, then resolve a certificate trust failure by embedding a CA bundle into a custom curl image

## Content Type

Lab (hands-on)

## Products & Technologies

- Red Hat Hardened Images
- Red Hat Enterprise Linux (RHEL)
- Red Hat Universal Base Images (UBI) — used as baseline comparison
- Podman
- Caddy — web server and TLS reverse proxy (sourced from RHHI catalog)
- OpenSSL — certificate inspection and FIPS policy verification
- Flask (Python) — sample demo application
- busybox — debug tooling installed in sidecar container

## Module Map

| Module | Title | Duration |
|--------|-------|----------|
| 1 | Introduction to Red Hat Hardened Images / UBI Baseline | 15 min |
| 2 | Hardened Image Variants (Distroless and Variants) | 25 min |
| 3 | Multi-Stage Builds and Operating Hardened Images | 30 min |
| 4 | Customized Security Images (FIPS Variant) | 20 min |
| 5 | TLS Reverse Proxy with Hardened Images | 30 min |
| — | **Total hands-on** | **120 min (2 hours)** |

## Difficulty Level

Intermediate

## Environment

**Learner view:** Participants access a RHEL virtual machine via a Wetty browser terminal. The Flask demo application (`rhhi-demo`) is pre-staged in `~/flask/`, with Containerfiles for UBI and RHHI variants ready to use. Module 5 additionally relies on pre-staged TLS configuration in `~/webserver/`. A browser tab to the running Flask application is available for observing runtime behavior (hash algorithm pass/fail in module 04; HTTPS verification in module 05). The RHHI image catalog is accessible at `registry.access.redhat.com`. Each student has an isolated environment accessed via a unique `{guid}.{domain}` URL.

**Automation needed:** Yes

Automation must provision per-student RHEL VMs with the following pre-staged resources:
- `~/flask/` directory containing the `rhhi-demo` Flask application source and all variant Containerfiles (UBI, distroless, builder, FIPS, multi-stage, sidecar)
- `~/webserver/` directory with Caddy configuration and self-generated TLS certificate material for module 05
- Podman pre-installed and configured with network access to `registry.access.redhat.com`
- Wildcard DNS and routing configured for per-student `{guid}.{domain}` URLs
- Ports 8080 (Flask) and 8443 (Caddy TLS) accessible from the learner's browser

## Infrastructure Requirements

- **Cloud provider:** CNV (default — single RHEL VM per student, no bare-metal or nested-virt requirement)
- **Cluster type:** N/A — RHEL VM lab, no OCP cluster
- **OCP version:** N/A
- **Topology:** Per-student — 1 RHEL VM per student
- **Sizing:** 1 RHEL 10 VM per student: 1 vCPU, 4 GB RAM, 40 GB disk (`rhel-10-0-07-09-25-3` image)
- **Automation approach:** Ansible — `setup-automation/` provisions the VM; `runtime-automation/` provides per-module setup/solve/validate scripts
- **AI/MaaS:** None
- **External services:** `registry.access.redhat.com` (TCP 443 — RHHI and UBI image pulls at setup time and during the lab); lab Git repository (TCP 443 — sparse-cloned at provision time to stage `~/flask/` Containerfiles)
- **AAP version:** N/A — not in products
- **Non-GA products:** None — all RHHI images (`hi/python:3.14`, `hi/core-runtime:latest-builder`, `hi/caddy:latest`, `hi/curl:latest` and their variants) are publicly available on `registry.access.redhat.com`
