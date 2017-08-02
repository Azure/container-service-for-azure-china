#!/usr/bin/env bash

REGISTRY_SERVER=$1.azurecr.io
REGISTRY_USERNAME=$1
REGISTRY_PASSWORD=$2
USERNAME=$3
PASSWORD=$4

docker login --username ${REGISTRY_USERNAME} --password ${REGISTRY_PASSWORD} ${REGISTRY_SERVER}

docker build -t ${REGISTRY_SERVER}/elasticsearch:1.0.0 ./elasticsearch
docker push ${REGISTRY_SERVER}/elasticsearch:1.0.0
docker build -t ${REGISTRY_SERVER}/kibana:1.0.0 --build-arg USERNAME=${USERNAME} --build-arg PASSWORD=${PASSWORD} ./kibana
docker push ${REGISTRY_SERVER}/kibana:1.0.0
docker build -t ${REGISTRY_SERVER}/logstash:1.0.0 ./logstash
docker push ${REGISTRY_SERVER}/logstash:1.0.0
docker build -t ${REGISTRY_SERVER}/filebeat:1.0.0 ./filebeat
docker push ${REGISTRY_SERVER}/filebeat:1.0.0
