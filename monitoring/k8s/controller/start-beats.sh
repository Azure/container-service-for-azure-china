#!/usr/bin/env bash

# terminate once a command failed
set -e

# create namespace
namespace=beats-ns

kubectl create namespace ${namespace}

# copy config file for Heartbeat
yes | cp -rf helm-chart-configs/heartbeat-config/heartbeat.yml ../helm-charts/heartbeat/config
# create Heartbeat
helm install -f helm-chart-configs/heartbeat.yaml ../helm-charts/heartbeat --name=heartbeat --namespace=${namespace}

