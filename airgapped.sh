#!/bin/sh

# Script for downloading and updating the repo for airgapped Neuvector installs

REGISTRY=harbor.lan.ping6.nl/neuvector
REGISTRY_HOST=$(echo $REGISTRY | awk -F '/' '{ print $1 }')
CHART_VERSION=2.8.1
HELM_REPO=neuvector-helm-charts
HELM_CHART_DIR=files/charts
IMAGES_DIR=files/images

ARCH_OVERRIDE="--override-os=linux --override-arch=amd64"

# Check if Skopeo Exists

if ! command -v skopeo &> /dev/null; then
  echo "-- skopeo not found, please install, see https://github.com/containers/skopeo"
  exit 1
else
  echo "-- skopeo found"
  echo "Login to registry: $REGISTRY_HOST"
  skopeo login $REGISTRY_HOST
fi

# Download Helm Chart

if [[ ! -d $HELM_CHART_DIR ]]; then
  mkdir -p $HELM_CHART_DIR
fi

# helm repo add $HELM_REPO https://neuvector.github.io/neuvector-helm/
# helm repo update

helm pull $HELM_REPO/crd -d $HELM_CHART_DIR --version $CHART_VERSION
helm pull $HELM_REPO/core -d $HELM_CHART_DIR --version $CHART_VERSION

# Get Images from Helm Chart

if [[ ! -d $IMAGES_DIR ]]; then
  mkdir -p $IMAGES_DIR
fi

helm template $HELM_CHART_DIR/core-$CHART_VERSION.tgz | awk '$1 ~ /image:/ {print $2}' | sed -e 's/\"//g' > $HELM_CHART_DIR/image-list.txt

# Download images

for IMAGE in $(cat $HELM_CHART_DIR/image-list.txt); do
  IMAGE_FILE_NAME=$IMAGES_DIR/$(echo $IMAGE| awk -F/ '{print $3}'|sed 's/:/_/g').tar
  IMAGE_NAME=$(echo $IMAGE| awk -F/ '{print $3}')
  if [[ ! -f $IMAGE_FILE_NAME ]]; then
    skopeo copy $ARCH_OVERRIDE docker://$IMAGE docker-archive:$IMAGE_FILE_NAME:$IMAGE_NAME
  fi
done

# Upload Images

for IMAGE in $(ls $IMAGES_DIR | grep .tar  ); do
    echo $IMAGE
    skopeo copy docker-archive:$IMAGES_DIR/$IMAGE docker://$(echo $IMAGE | sed 's/.tar//g' | awk -F_ '{print "'$REGISTRY'/"$1":"$2}')
done
