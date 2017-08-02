#!/bin/sh

if [ -z "${NODE_NAME}" ]; then
	NODE_NAME=$(uuidgen)
fi
export NODE_NAME=${NODE_NAME}

mkdir -p /data
chown -R elasticsearch:elasticsearch /data

sudo -E -u elasticsearch /elasticsearch/bin/elasticsearch
