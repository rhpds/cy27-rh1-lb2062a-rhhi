#!/bin/bash
USER=rhel

echo "Adding wheel" > /root/post-run.log
usermod -aG wheel rhel

echo "Starting setup for zt-hardened-images" > /tmp/progress.log

chmod 666 /tmp/progress.log

# Fetch setup files from the lab git repository
TMPDIR=/tmp/lab-setup-$$
git clone --single-branch --branch ${GIT_BRANCH:-main} --no-checkout \
  --depth=1 --filter=tree:0 ${GIT_REPO} $TMPDIR
git -C $TMPDIR sparse-checkout set --no-cone /content/modules/ROOT/examples/flask
git -C $TMPDIR checkout
SETUP_FILES=$TMPDIR/content/modules/ROOT/examples/flask

# Copy Flask app files
mkdir -p /home/rhel/flask
cp $SETUP_FILES/app.py /home/rhel/flask/app.py
cp $SETUP_FILES/Containerfile.ubi /home/rhel/flask/Containerfile.ubi
cp $SETUP_FILES/Containerfile.hardened /home/rhel/flask/Containerfile.hardened
cp $SETUP_FILES/Containerfile.fips /home/rhel/flask/Containerfile.fips
chown -R rhel:rhel /home/rhel/flask
echo "Flask app files copied" >> /tmp/progress.log

# Generate Caddyfile with the provisioned hostname so Caddy issues a cert for the correct SNI
mkdir -p /home/rhel/webserver
cat > /home/rhel/webserver/Caddyfile << EOF
{
	auto_https disable_redirects
}

caddy-${GUID}.${DOMAIN}:8443 {
	tls internal
	reverse_proxy localhost:8080
}
EOF
chown -R rhel:rhel /home/rhel/webserver
echo "Caddyfile generated" >> /tmp/progress.log

# Cleanup sparse checkout
rm -rf $TMPDIR

# Pre-pull base images into rhel user's podman storage
runuser -l rhel -c "podman pull registry.access.redhat.com/ubi10/ubi"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/python:3.14-builder"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/python:3.14"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/python:3.14-fips"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/python:3.14-fips-builder"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/caddy:latest"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/curl:latest"
runuser -l rhel -c "podman pull registry.access.redhat.com/hi/curl:latest-builder"
echo "Base images pre-pulled" >> /tmp/progress.log

# Pre-build UBI baseline image so module-01 participants don't wait for it
runuser -l rhel -c "podman build -t rhhi-demo:ubi -f /home/rhel/flask/Containerfile.ubi /home/rhel/flask"
echo "rhhi-demo:ubi pre-built" >> /tmp/progress.log

echo "Setup complete" >> /tmp/progress.log
