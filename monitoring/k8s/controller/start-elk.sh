#!/usr/bin/env bash

# terminate once a command failed
set -e

# substitute environment variables
cat config.yaml | envsubst > effect.yaml

# create namespace
namespace=elk-cluster-ns

helm install -f config.yaml ns

# create secret
registry_name=azure-registry
registry_server=$1.azurecr.io
registry_username=$1
registry_password=$2
registry_email=example@example.com

kubectl --namespace=${namespace} create secret docker-registry ${registry_name} \
--docker-server=${registry_server} \
--docker-username=${registry_username} \
--docker-password=${registry_password} \
--docker-email=${registry_email}

# create Elasticsearch
helm install -f effect.yaml es

# create Kibana
helm install -f effect.yaml kibana

# create Logstash
helm install -f effect.yaml logstash
