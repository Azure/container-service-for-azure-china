#!/bin/env bash

# usages: run this script in k8s master node, then could access http://{master_dns}/ui to open k8s dashboard
# sample: bash /path/to/script/config_k8s_ui_http.sh -c AzureChinaCloud -g <rg_name> -t <tenant_id> -i <app_id> -s <app_secret> -u <user_name> -p <user_pass>

set -e

function log() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") $1"
}

usage(){
  echo "Invalid option: -$OPTARG"
  echo "Usage: deploy-docker-registry -c [Cloud instance name, AzureCloud or AzureChinaCloud]"
  echo "                              -g [Resource group]"
  echo "                              -t [Service principal tenant id, e.g. foo.onmicrosoft.com, bar.partner.onmschina.cn etc. ]"
  echo "                              -i [Service principal app id]"
  echo "                              -s [Service principal secret]"
  echo "                              -u [Kubernetes dashboard user name, default value is 'admin']"
  echo "                              -p [Kubernetes dashboard user password, default value is 'password']"
  exit 1
}

while getopts ":c:g:t:i:s:u:p:" opt; do
  case $opt in
    c)CLOUD_NAME=$OPTARG;;
    g)RESOURCE_GROUP=$OPTARG;;
    t)TENANT_ID=$OPTARG;;
    i)APP_ID=$OPTARG;;
    s)APP_SECRET=$OPTARG;;
    u)USER_NAME=$OPTARG;;
    p)USER_PASS=$OPTARG;;
    *)usage;;
  esac
done

function main() {
    # ensure kubectl worked well
    log "check kubectl version"
    kubectl version

    # install nginx in master node
    log "install nginx"
    sudo apt-get install -q -y nginx apache2-utils

    # set username and password for k8s dashboard login
    log "set user name and password"
    admin_user="${USER_NAME:-admin}"
    admin_pass="${USER_PASS:-password}"
    echo "${admin_pass}" | sudo htpasswd -c -i /etc/nginx/.htpasswd "${admin_user}"

    # set nginx site config
    log "set nginx site config"
    echo 'server {
        listen 80 default_server;
        listen [::]:80 default_server;

        server_name _;

        location / {
                   proxy_pass http://localhost:8080;
                      auth_basic "Restrict Access";
                   auth_basic_user_file /etc/nginx/.htpasswd;
           }
}' | sudo tee "/etc/nginx/sites-available/default"

    # set proxy from local port 8080 to k8s dashboard
    log "set kubectl proxy"
    sudo sh -c 'nohup kubectl proxy --port=8080 > "/var/log/kubeproxy.log" 2>&1 &'

    # activate nginx config
    log "activate nginx config"
    sudo systemctl reload nginx

    # test
    log "test nginx"
    sleep 10
    curl -L http://localhost/ui -u "${admin_user}:${admin_pass}"

    # install azure cli 2.0
    log "install azure cli 2.0"
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
    sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
    sudo apt-get install -q -y apt-transport-https
    sudo apt-get update
    sudo apt-get install -q -y azure-cli

    # azure cli login
    log "azure cli login"
    az cloud set -n ${CLOUD_NAME:-AzureCloud}
    az login --service-principal -u ${APP_ID} -p ${APP_SECRET} --tenant ${TENANT_ID}

    # create nsg rule
    log "create network security group rule"
    nsg_rule="allow-http"
    nsg_name=`hostname | sed "s/-0/-nsg/"`
    az network nsg rule create -g "${RESOURCE_GROUP}" --nsg-name nsg_name -n "${nsg_name}" --priority 111 --protocol Tcp --destination-port-ranges 80

    # create lb nat rule
    nat_rule_name="allow-master-http"
    log "create load balancer nat rule"
    lb_name=`hostname | sed "s/\([0-9]*\)-0/\1-lb/"`
    az network lb inbound-nat-rule create -g "${RESOURCE_GROUP}" -n "${nat_rule_name}" --lb-name "${lb_name}" --protocol Tcp --frontend-port 80 --backend-port 80

    # assign nic inbound rule
    log "assign nic inbound rule"
    nic_name=`hostname | sed s/-0/-nic-0/`
    az network nic ip-config inbound-nat-rule add -g "${RESOURCE_GROUP}" -n "ipconfig1" --nic-name "${nic_name}" --lb-name "${lb_name}" --inbound-nat-rule "${nat_rule_name}"

    log "kubernetes dashboard config success."
}

main 2>&1 | tee -a config_k8s_ui_http.log