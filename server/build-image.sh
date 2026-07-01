#!/bin/bash
set -e

cd "$(dirname "$0")"

if [ ! -e target/.done ]; then
    mkdir -p target
    curl -sL -o target/s6-overlay-amd64-static.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.19.1.1/s6-overlay-amd64.tar.gz
    touch target/.done
fi

if [ -f ../rancher-1.6-cattle/dist/artifacts/cattle.jar ]; then
    echo "Copying custom built cattle.jar..."
    cp ../rancher-1.6-cattle/dist/artifacts/cattle.jar artifacts/cattle.jar
else
    echo "Error: Custom cattle.jar not found at ../rancher-1.6-cattle/dist/artifacts/cattle.jar"
    exit 1
fi

TAG=${TAG:-$(awk '/ENV CATTLE_RANCHER_SERVER_VERSION/{print $3}' Dockerfile)}
REPO=${REPO:-$(awk '/ENV CATTLE_RANCHER_SERVER_IMAGE/{print $3}' Dockerfile)}
IMAGE=${REPO}:${TAG}

docker build -t "${IMAGE}" .


cat > Dockerfile.master << EOF
FROM ${IMAGE}
ENV CATTLE_MASTER true
EOF
trap "rm Dockerfile.master" EXIT

docker build -t "${REPO}:master" -f Dockerfile.master .

echo Done building "${IMAGE}"
