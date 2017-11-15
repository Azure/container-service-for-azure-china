#!/bin/env bash

usage(){
  echo "Invalid option: -$OPTARG"
  echo "Usage: config-insecure-registry -r [Registry fqdn]"
  echo "                                -p [Registry port, default value: 5000]"
  echo "                                -m [k8s master node fqdn]"
  echo "                                -u [user name for SSH to k8s nodes]"
  echo "                                -k [id_rsa file for SSH to k8s nodes]"
  exit 1
}

while getopts ":r:p:m:k:u:" opt; do
  case $opt in
    r)REG_FQDN=$OPTARG;;
    p)REG_PORT=$OPTARG;;
    m)K8S_MASTER=$OPTARG;;
    u)K8S_USER=$OPTARG;;
    k)ID_RSA_FILE=$OPTARG;;
    *)usage;;
  esac
done

function upload_to_master() {
    src_path=$1
    dest_path=$2

    sudo scp -i "$ID_RSA_FILE" -oStrictHostKeyChecking=no "$src_path" $K8S_USER@$K8S_MASTER:$dest_path
}

function download_from_master() {
    src_path=$1
    dest_path=$2

    sudo scp -i "$ID_RSA_FILE" -oStrictHostKeyChecking=no $K8S_USER@$K8S_MASTER:$src_path "$dest_path"
}

function run_in_master() {
    cmd="$*"

    ssh -i "$ID_RSA_FILE" -oStrictHostKeyChecking=no $K8S_USER@$K8S_MASTER $cmd
}

function main() {
    log_in_master="/var/log/config-insecure-reg.log"

    id_rsa_in_master="/tmp/k8s_id_rsa"
    upload_to_master $ID_RSA_FILE $id_rsa_in_master
    run_in_master sudo chmod 400 $id_rsa_in_master
    run_in_master sudo chown $K8S_USER:$K8S_USER $id_rsa_in_master
    echo "uploaded id_rsa file from '$ID_RSA_FILE' to '$id_rsa_in_master' in master"

    temp_script="config-insecure-reg.sh"
    cp "config-insecure-registry-in-master.sh" $temp_script
    sed -i "s/{{{REG_FQDN}}}/$REG_FQDN/" $temp_script
    sed -i "s/{{{REG_PORT}}}/${REG_PORT:-5000}/" $temp_script
    sed -i "s/{{{K8S_USER}}}/$K8S_USER/" $temp_script
    sed -i "s|{{{ID_RSA_FILE}}}|$id_rsa_in_master|" $temp_script
    sed -i "s|{{{LOG_IN_MASTER}}}|$log_in_master|" $temp_script

    temp_script_in_master="/tmp/$temp_script"
    upload_to_master $temp_script $temp_script_in_master
    echo "uploaded script to '$temp_script_in_master' in master"
    echo "script content:"
    cat $temp_script

    rm -f $temp_script

    echo "running script '$temp_script_in_master' in master"
    run_in_master bash $temp_script_in_master

    echo "downloading log in master from '$log_in_master'"
    master_log="config-insecure-registry-in-master.log"
    download_from_master $log_in_master $master_log

    echo "cleaning up in master"
    run_in_master sudo rm -f $id_rsa_in_master
    run_in_master sudo rm -f $temp_script_in_master

    echo "config insecure registry done."
}

main 2>&1 | tee -a config-insecure-registry.log