#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

export DATA_STORAGE_ACCOUNT=$1

echo "dataStorageAccount: $DATA_STORAGE_ACCOUNT" | tee ~/config.log