#!/bin/sh

# Installation script for installation and update of Neuvector

NAMESPACE=neuvector
CHART_VERSION=2.8.1
HELM_REPO=neuvector-helm-charts
HELM_CHART_DIR=files/charts

helm upgrade --install --namespace $NAMESPACE neuvector $HELM_CHART_DIR/core-$CHART_VERSION.tgz --create-namespace --values values.yaml

kubectl --namespace $NAMESPACE create secret tls tls-ingress \
  --cert=fullchain.pem \
  --key=privkey.pem
