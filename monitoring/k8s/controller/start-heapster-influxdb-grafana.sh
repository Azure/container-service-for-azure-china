#!/usr/bin/env bash

# terminate once a command failed
set -e

# create namespace
namespace=monitoring-ns

kubectl create namespace ${namespace}

# create Influxdb
helm install -f helm-chart-configs/influxdb.yaml ../helm-charts/influxdb --name=influxdb --namespace=${namespace}

# create Heapster
helm install -f helm-chart-configs/heapster.yaml ../helm-charts/heapster --name=heapster --namespace=${namespace}

# create Grafana
helm install -f helm-chart-configs/grafana.yaml ../helm-charts/grafana --name=grafana --namespace=${namespace}
