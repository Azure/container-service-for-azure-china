#!/bin/env bash

function main() {
    sudo apt-get -q -y install jq moreutils

    daemon_file="/etc/docker/daemon.json"

    echo "original daemon file:"
    cat $daemon_file

    sudo cat "$daemon_file" | jq '."insecure-registries"[0]="{{{REG_FQDN}}}:{{{REG_PORT}}}"' | sudo sponge "$daemon_file"
    sudo service docker restart

    echo "updated daemon file:"
    cat $daemon_file

    local_name=`hostname`
    temp_daemon_file="/tmp/daemon.json"
    for node_name in `kubectl get nodes -o=jsonpath={.items[*].metadata.name}`
    do
    if [ "$local_name" != "$node_name" ] ; then
        sudo scp -i "{{{ID_RSA_FILE}}}" -oStrictHostKeyChecking=no "$daemon_file" {{{K8S_USER}}}@$node_name:$temp_daemon_file
        ssh -i "{{{ID_RSA_FILE}}}" -oStrictHostKeyChecking=no {{{K8S_USER}}}@$node_name sudo mv $temp_daemon_file "$daemon_file"
        ssh -i "{{{ID_RSA_FILE}}}" -oStrictHostKeyChecking=no {{{K8S_USER}}}@$node_name sudo service docker restart

        echo "copy daemon file to node '$node_name'"
    fi
    done
}

main 2>&1 | sudo tee -a "{{{LOG_IN_MASTER}}}"