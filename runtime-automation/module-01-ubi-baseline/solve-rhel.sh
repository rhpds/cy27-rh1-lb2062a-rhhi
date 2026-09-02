#!/bin/sh
echo "Solving module-01: UBI Baseline" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
podman run -d --name rhhi-ubi -p 8080:8080 rhhi-demo:ubi
sleep 2
curl -s http://localhost:8080/
podman run --rm rhhi-demo:ubi rpm -qa | wc -l
podman stop rhhi-ubi
podman rm rhhi-ubi
RHEL_EOF

echo "module-01 solve complete" >> /tmp/progress.log
