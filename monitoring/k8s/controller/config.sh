#!/usr/bin/env bash
#
# Config controller VM environments.
#
# Usages:
#
# Sample for Public Azure Environment:
# bash config.sh --k8s-master-node-hostname "k8s-cluster-master.eastasia.cloudapp.azure.com" \
#                --k8s-master-node-username "azureuser" \
#                --k8s-master-node-id-file-base64 "<K8S_MASTER_NODE_IDENTITY_FILE_BASE64>" \
#                --k8s-ui-admin-username "azureuser" \
#                --k8s-ui-admin-password "<K8S_UI_ADMIN_PASSWORD>" \
#                --monitor-cluster-ns "monitor-cluster-ns" \
#                --enable-elk-stack "enabled" \
#                --enable-hig-stack "enabled"
#
# Sample for Azure China Environment:
# bash config.sh --azure-cloud-env "AzureChinaCloud" \
#                --k8s-master-node-hostname "k8s-cluster-master.chinaeast.cloudapp.azure.cn" \
#                --k8s-master-node-username "azureuser" \
#                --k8s-master-node-id-file-base64 "<K8S_MASTER_NODE_IDENTITY_FILE_BASE64>"
#                --k8s-ui-admin-username "azureuser" \
#                --k8s-ui-admin-password "<K8S_UI_ADMIN_PASSWORD>"
#                --monitor-cluster-ns "monitor-cluster-ns" \
#                --enable-elk-stack "enabled" \
#                --enable-hig-stack "enabled"
#

set -e

# =============================================================================
# constants
# =============================================================================

# script version
readonly SCRIPT_VERSION="v0.0.22"

# enable feature flag
readonly ENABLED="enabled"

# disable feature flag
readonly DISABLED="disabled"

# azure environments
readonly AZURE_CLOUD="AzureCloud"
readonly AZURE_CHINA_CLOUD="AzureChinaCloud"

# install directory
readonly INSTALL_DIR="/tmp/install"

# log file
readonly LOG_FILE="$INSTALL_DIR/config.log"
readonly KUBE_PROXY_LOG_FILE="$INSTALL_DIR/kube_proxy.log"

# cleanup script file
readonly CLEANUP_SCRIPT_PATH="$INSTALL_DIR/cleanup.sh"

# docker package constants
readonly OFFICIAL_DOCKER_PACKAGE_URL="https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_17.06.0~ce-0~ubuntu_amd64.deb"
readonly MIRROR_DOCKER_PACKAGE_URL="https://mirror.azure.cn/docker-engine/apt/repo/pool/main/d/docker-engine/docker-engine_17.05.0~ce-0~ubuntu-xenial_amd64.deb"
readonly DOCKER_PACKAGE_NAME="docker-ce.deb"
readonly DOCKER_PACKAGE_LOCAL_PATH="$INSTALL_DIR/$DOCKER_PACKAGE_NAME"

# kubectl constants
readonly KUBECTL_VERSION="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
readonly KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
# set default version to v1.7.7 if can't get stable version from remote
# TODO: move this setting to arm template
readonly KUBECTL_MIRROR_URL="https://mirror.azure.cn/kubernetes/kubectl/${KUBECTL_VERSION:-v1.7.7}/bin/linux/amd64/kubectl"
readonly KUBECTL_TEMP_PATH="$INSTALL_DIR/kubectl"
readonly KUBECTL_INSTALL_PATH="/usr/local/bin/kubectl"

# kubenetes constants
readonly K8S_MASTER_NODE_IDENTITY_FILE_PATH="$INSTALL_DIR/k8s_id"
readonly K8S_MASTER_NODE_KUBE_CONFIG_PATH="~/.kube/config"
readonly K8S_NAMESPACE_KUBE_SYSTEM="kube-system"

# kube config constants
readonly KUBE_CONFIG_LOCAL_DIR="/root/.kube"
readonly KUBE_CONFIG_LOCAL_PATH="$KUBE_CONFIG_LOCAL_DIR/config"
export KUBECONFIG="$KUBE_CONFIG_LOCAL_PATH"

# helm contstants
readonly HELM_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get"
readonly HELM_INSTALL_SCRIPT_LOCAL_PATH="$INSTALL_DIR/install_helm.sh"
# fix helm version to v2.6.1
# TODO: move this setting to arm template
#readonly HELM_TAG="$(curl -SsL https://github.com/kubernetes/helm/releases/latest | awk '/\/tag\//' | head -n 1 | cut -d '"' -f 2 | awk '{n=split($NF,a,"/");print a[n]}')"
readonly HELM_TAG="v2.6.1"
readonly HELM_DIST="helm-${HELM_TAG}-linux-amd64.tar.gz"
readonly HELM_DOWNLOAD_MIRROR="https://mirror.azure.cn/kubernetes/helm/${HELM_DIST}"

# microservice reference architecture project constants
readonly GITHUB_REPO="GIT" # download from GitHub repo
readonly HTTP_DIRECT="HTTP" # download zip package directly via HTTP
readonly MSREF_LOCAL_PATH="$INSTALL_DIR/msref"
readonly MSREF_HTTP_DOWNLOAD_TEMP_PATH="$INSTALL_DIR/msref.zip"

# helm charts constants
readonly HELM_CHARTS_LOCAL_PATH="$MSREF_LOCAL_PATH/monitoring/k8s/helm-charts"
readonly HELM_CHARTS_CONFIG_LOCAL_PATH="$MSREF_LOCAL_PATH/monitoring/k8s/helm-charts/configs"
readonly HELM_CHART_ELK_PATH="$HELM_CHARTS_LOCAL_PATH/elk"
readonly HELM_CHART_ELK_AZURE_CHINA_CONFIG_PATH="$HELM_CHARTS_CONFIG_LOCAL_PATH/elk_azure_china_cloud.yaml"
readonly HELM_CHART_HEARTBEAT_PATH="$HELM_CHARTS_LOCAL_PATH/heartbeat"
readonly HELM_CHART_HEARTBEAT_CONFIG_PATH="$HELM_CHARTS_CONFIG_LOCAL_PATH/heartbeat.yaml"
readonly HELM_CHART_INFLUXDB_PATH="$HELM_CHARTS_LOCAL_PATH/influxdb"
readonly HELM_CHART_INFLUXDB_CONFIG_PATH="$HELM_CHARTS_CONFIG_LOCAL_PATH/influxdb.yaml"
readonly HELM_CHART_HEAPSTER_PATH="$HELM_CHARTS_LOCAL_PATH/heapster"
readonly HELM_CHART_HEAPSTER_CONFIG_PATH="$HELM_CHARTS_CONFIG_LOCAL_PATH/heapster.yaml"
readonly HELM_CHART_GRAFANA_PATH="$HELM_CHARTS_LOCAL_PATH/grafana"
readonly HELM_CHART_GRAFANA_CONFIG_PATH="$HELM_CHARTS_CONFIG_LOCAL_PATH/grafana.yaml"

# nginx constants
readonly MSREF_NGINX_SITE_CONFIG_PATH="$MSREF_LOCAL_PATH/monitoring/k8s/controller/nginx-config/nginx-site.conf"
readonly NGINX_DEFAULT_SITE_PATH="/etc/nginx/sites-available/default"

# =============================================================================
# command line arguments
# =============================================================================

# options
readonly ARG_HELP="--help"
readonly ARG_HELP_ALIAS="-h"
readonly ARG_K8S_MASTER_NODE_HOSTNAME="--k8s-master-node-hostname"
readonly ARG_K8S_MASTER_NODE_USERNAME="--k8s-master-node-username"
readonly ARG_K8S_MASTER_NODE_IDENTITY_FILE_BASE64="--k8s-master-node-id-file-base64"
readonly ARG_K8S_UI_ADMIN_USERNAME="--k8s-ui-admin-username"
readonly ARG_K8S_UI_ADMIN_PASSWORD="--k8s-ui-admin-password"
readonly ARG_MONITOR_CLUSTER_NS="--monitor-cluster-ns"
readonly ARG_AZURE_CLOUD_ENVIRONMENT="--azure-cloud-env"
readonly ARG_MSREF_DOWNLOAD_METHOD="--msref-download-method"
readonly ARG_MSREF_HTTP_URL="--maref-http-url"
readonly ARG_MSREF_REPO_ACCOUNT="--msref-repo-account"
readonly ARG_MSREF_REPO_PROJECT="--msref-repo-project"
readonly ARG_MSREF_REPO_BRANCH="--maref-repo-branch"
readonly ARG_ENABLE_ELK_STACK="--enable-elk-stack"
readonly ARG_ENABLE_HIG_STACK="--enable-hig-stack"

# default values
readonly DEFAULT_MONITOR_CLUSTER_NS="monitor-cluster-ns"
readonly DEFAULT_AZURE_CLOUD_ENVIRONMENT="$AZURE_CLOUD"
readonly DEFAULT_MSREF_DOWNLOAD_METHOD="$HTTP_DIRECT"
readonly DEFAULT_MSREF_HTTP_URL="https://github.com/Azure/devops-sample-solution-for-azure-china/archive/eshop.zip"
readonly DEFAULT_MSREF_ZIP_NAME="$INSTALL_DIR/devops-sample-solution-for-azure-china-eshop"
readonly DEFAULT_MSREF_REPO_ACCOUNT="Azure"
readonly DEFAULT_MSREF_REPO_PROJECT="devops-sample-solution-for-azure-china"
readonly DEFAULT_MSREF_REPO_BRANCH="master"
readonly DEFAULT_ENABLE_ELK_STACK="$ENABLED"
readonly DEFAULT_ENABLE_HIG_STACK="$ENABLED"

# variables
K8S_MASTER_NODE_HOSTNAME=""
K8S_MASTER_NODE_USERNAME=""
K8S_MASTER_NODE_IDENTITY_FILE_BASE64=""
K8S_UI_ADMIN_USERNAME=""
K8S_UI_ADMIN_PASSWORD=""
MONITOR_CLUSTER_NS="$DEFAULT_MONITOR_CLUSTER_NS"
AZURE_CLOUD_ENVIRONMENT="$DEFAULT_AZURE_CLOUD_ENVIRONMENT"
MSREF_DOWNLOAD_METHOD="$DEFAULT_MSREF_DOWNLOAD_METHOD"
MSREF_HTTP_URL="$DEFAULT_MSREF_HTTP_URL"
MSREF_REPO_ACCOUNT="$DEFAULT_MSREF_REPO_ACCOUNT"
MSREF_REPO_PROJECT="$DEFAULT_MSREF_REPO_PROJECT"
MSREF_REPO_BRANCH="$DEFAULT_MSREF_REPO_BRANCH"

# =============================================================================
# feature flags, could change on demand.
# =============================================================================

# flag to enable docker package mirror or not.
ENABLE_DOCKER_PACKAGE_MIRROR_FLAG="$ENABLED"

# flag to enable kubectl mirror or not.
ENABLE_KUBECTL_MIRROR_FLAG="$ENABLED"

# flag to enable helm tiller image mirror or not
ENABLE_HELM_MIRROR_FLAG="$ENABLED"

# flag to enable elk stack
ENABLE_ELK_STACK="$ENABLED"

# flag to enable heapster-inluxdb-grafana (HIG) stack
ENABLE_HIG_STACK="$ENABLED"

# =============================================================================
# functions
# =============================================================================

# -----------------------------------------------------------------------------
# Help function.
# Globals:
#   ENABLED
#   DISABLED
#   AZURE_CLOUD
#   AZURE_CHINA_CLOUD
#   GITHUB_REPO
#   HTTP_DIRECT
#   ARG_HELP
#   ARG_HELP_ALIAS
#   ARG_K8S_MASTER_NODE_HOSTNAME
#   ARG_K8S_MASTER_NODE_USERNAME
#   ARG_K8S_MASTER_NODE_IDENTITY_FILE_BASE64
#   ARG_K8S_UI_ADMIN_USERNAME
#   ARG_K8S_UI_ADMIN_PASSWORD
#   ARG_MONITOR_CLUSTER_NS
#   ARG_AZURE_CLOUD_ENVIRONMENT
#   ARG_MSREF_DOWNLOAD_METHOD
#   ARG_MSREF_HTTP_URL
#   ARG_MSREF_REPO_ACCOUNT
#   ARG_MSREF_REPO_PROJECT
#   ARG_MSREF_REPO_BRANCH
#   ARG_ENABLE_ELK_STACK
#   ARG_ENABLE_HIG_STACK
#   DEFAULT_MONITOR_CLUSTER_NS
#   DEFAULT_AZURE_CLOUD_ENVIRONMENT
#   DEFAULT_MSREF_DOWNLOAD_METHOD
#   DEFAULT_MSREF_HTTP_URL
#   DEFAULT_MSREF_REPO_ACCOUNT
#   DEFAULT_MSREF_REPO_PROJECT
#   DEFAULT_MSREF_REPO_BRANCH
#   DEFAULT_ENABLE_ELK_STACK
#   DEFAULT_ENABLE_HIG_STACK
#   K8S_MASTER_NODE_HOSTNAME
#   K8S_MASTER_NODE_USERNAME
#   K8S_MASTER_NODE_IDENTITY_FILE_BASE64
#   K8S_UI_ADMIN_USERNAME
#   K8S_UI_ADMIN_PASSWORD
#   MONITOR_CLUSTER_NS
#   AZURE_CLOUD_ENVIRONMENT
#   MSREF_DOWNLOAD_METHOD
#   MSREF_HTTP_URL
#   MSREF_REPO_ACCOUNT
#   MSREF_REPO_PROJECT
#   MSREF_REPO_BRANCH
#   ENABLE_ELK_STACK
#   ENABLE_HIG_STACK
# Arguments:
#   None
# Returns:
#   None
# -----------------------------------------------------------------------------
function help() {
    echo "This script is used to config controller VM environments"
    echo "options:"
    echo "	$ARG_HELP or $ARG_HELP_ALIAS: help hints"
    echo "	$ARG_K8S_MASTER_NODE_HOSTNAME: required, kubernetes cluster master node hostname"
    echo "	$ARG_K8S_MASTER_NODE_USERNAME: required, kubernetes cluster master node username"
    echo "	$ARG_K8S_MASTER_NODE_IDENTITY_FILE_BASE64: required, kubernetes cluster master node identity file in base64 encoded string"
    echo "	$ARG_K8S_UI_ADMIN_USERNAME: required, kubernetes ui admin username"
    echo "	$ARG_K8S_UI_ADMIN_PASSWORD: required, kubernetes ui admin password"
    echo "	$ARG_MONITOR_CLUSTER_NS: optional, monitoring cluster namespace in kubernetes, default value: '$DEFAULT_MONITOR_CLUSTER_NS'"
    echo "	$ARG_AZURE_CLOUD_ENVIRONMENT: optional, azure cloud environment '$AZURE_CLOUD' or '$AZURE_CHINA_CLOUD', default value: '$DEFAULT_AZURE_CLOUD_ENVIRONMENT'"
    echo "	$ARG_MSREF_DOWNLOAD_METHOD: optional, microservice reference architecture download method '$HTTP_DIRECT' or '$GITHUB_REPO', default value: '$DEFAULT_MSREF_DOWNLOAD_METHOD'"
    echo "	$ARG_MSREF_HTTP_URL: optional, microservice reference architecture http download url, default value: '$DEFAULT_MSREF_HTTP_URL'"
    echo "	$ARG_MSREF_REPO_ACCOUNT: optional, microservice reference architecture GitHub repo account name, default value: '$DEFAULT_MSREF_REPO_ACCOUNT'"
    echo "	$ARG_MSREF_REPO_PROJECT: optional, microservice reference architecture GitHub repo project name, default value: '$DEFAULT_MSREF_REPO_PROJECT'"
    echo "	$ARG_MSREF_REPO_BRANCH: optional, microservice reference architecture GitHub repo project branch, default value: '$DEFAULT_MSREF_REPO_BRANCH'"
    echo "	$ARG_ENABLE_ELK_STACK: optional, set elk stack '$ENABLED' or '$DISABLED', default value: '$DEFAULT_ENABLE_ELK_STACK'"
    echo "	$ARG_ENABLE_HIG_STACK: optional, set heapster-influxdb-grafana stack '$ENABLED' or '$DISABLED', default value: '$DEFAULT_ENABLE_HIG_STACK'"
}

# -----------------------------------------------------------------------------
# Log message to standard output.
# Globals:
#   LOG_FILE
# Arguments:
#   message
# Returns:
#   None
# -----------------------------------------------------------------------------
function log_message() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") $1"
}

# -----------------------------------------------------------------------------
# Log message directly to file.
# Globals:
#   LOG_FILE
# Arguments:
#   message
# Returns:
#   None
# -----------------------------------------------------------------------------
function log_message_direct() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") $1" | tee -a $LOG_FILE
}

# -----------------------------------------------------------------------------
# Parse command line arguments function.
# Globals:
#   ENABLED
#   DISABLED
#   AZURE_CLOUD
#   AZURE_CHINA_CLOUD
#   GITHUB_REPO
#   HTTP_DIRECT
#   ARG_HELP
#   ARG_HELP_ALIAS
#   ARG_K8S_MASTER_NODE_HOSTNAME
#   ARG_K8S_MASTER_NODE_USERNAME
#   ARG_K8S_MASTER_NODE_IDENTITY_FILE_BASE64
#   ARG_K8S_UI_ADMIN_USERNAME
#   ARG_K8S_UI_ADMIN_PASSWORD
#   ARG_MONITOR_CLUSTER_NS
#   ARG_AZURE_CLOUD_ENVIRONMENT
#   ARG_MSREF_DOWNLOAD_METHOD
#   ARG_MSREF_HTTP_URL
#   ARG_MSREF_REPO_ACCOUNT
#   ARG_MSREF_REPO_PROJECT
#   ARG_MSREF_REPO_BRANCH
#   ARG_ENABLE_ELK_STACK
#   ARG_ENABLE_HIG_STACK
#   K8S_MASTER_NODE_HOSTNAME
#   K8S_MASTER_NODE_USERNAME
#   K8S_MASTER_NODE_IDENTITY_FILE_BASE64
#   K8S_UI_ADMIN_USERNAME
#   K8S_UI_ADMIN_PASSWORD
#   MONITOR_CLUSTER_NS
#   AZURE_CLOUD_ENVIRONMENT
#   MSREF_DOWNLOAD_METHOD
#   MSREF_HTTP_URL
#   MSREF_REPO_ACCOUNT
#   MSREF_REPO_PROJECT
#   MSREF_REPO_BRANCH
#   ENABLE_ELK_STACK
#   ENABLE_HIG_STACK
# Arguments:
#   command line arguments: $@
# Returns:
#   None
# -----------------------------------------------------------------------------
function parse_args() {
    while [[ "$#" -gt 0 ]]
    do

        arg_value="${2}"
        shift_once=0

        if [[ "$arg_value" =~ "--" ]] ; then
            arg_value=""
            shift_once=1
        fi

        log_message_direct "Option '${1}' set with value '"$arg_value"'"

        case "$1" in
            $ARG_HELP_ALIAS|$ARG_HELP)
                help
                exit 2
                ;;
            $ARG_K8S_MASTER_NODE_HOSTNAME)
                K8S_MASTER_NODE_HOSTNAME="$arg_value"
                ;;
            $ARG_K8S_MASTER_NODE_USERNAME)
                K8S_MASTER_NODE_USERNAME="$arg_value"
                ;;
            $ARG_K8S_MASTER_NODE_IDENTITY_FILE_BASE64)
                K8S_MASTER_NODE_IDENTITY_FILE_BASE64="$arg_value"
                ;;
            $ARG_K8S_UI_ADMIN_USERNAME)
                K8S_UI_ADMIN_USERNAME="$arg_value"
                ;;
            $ARG_K8S_UI_ADMIN_PASSWORD)
                K8S_UI_ADMIN_PASSWORD="$arg_value"
                ;;
            $ARG_MONITOR_CLUSTER_NS)
                MONITOR_CLUSTER_NS="$arg_value"
                ;;
            $ARG_AZURE_CLOUD_ENVIRONMENT)
                if [ "$arg_value" = "$AZURE_CLOUD" ] || \
                   [ "$arg_value" = "$AZURE_CHINA_CLOUD" ] ; then
                    AZURE_CLOUD_ENVIRONMENT="$arg_value"
                else
                    log_message_direct "ERROR: invalid argument value: $arg_value"
                    help
                    exit 2
                fi
                ;;
            $ARG_MSREF_DOWNLOAD_METHOD)
                if [ "$arg_value" = "$HTTP_DIRECT" ] || \
                   [ "$arg_value" = "$GITHUB_REPO" ] ; then
                    MSREF_DOWNLOAD_METHOD="$arg_value"
                else
                    log_message_direct "ERROR: invalid argument value: $arg_value"
                    help
                    exit 2
                fi
                ;;
            $ARG_MSREF_HTTP_URL)
                MSREF_HTTP_URL="$arg_value"
                ;;
            $ARG_MSREF_REPO_ACCOUNT)
                MSREF_REPO_ACCOUNT="$arg_value"
                ;;
            $ARG_MSREF_REPO_PROJECT)
                MSREF_REPO_PROJECT="$arg_value"
                ;;
            $ARG_MSREF_REPO_BRANCH)
                MSREF_REPO_BRANCH="$arg_value"
                ;;
            $ARG_MONITOR_CLUSTER_NS)
                MONITOR_CLUSTER_NS="$arg_value"
                ;;
            $ARG_ENABLE_ELK_STACK)
                if [ "${arg_value,,}" = "$ENABLED" ] || \
                   [ "${arg_value,,}" = "$DISABLED" ] ; then
                    ENABLE_ELK_STACK="${arg_value,,}"
                else
                    log_message_direct "ERROR: invalid argument value: $arg_value"
                    help
                    exit 2
                fi
                ;;
            $ARG_ENABLE_HIG_STACK)
                if [ "${arg_value,,}" = "$ENABLED" ] || \
                   [ "${arg_value,,}" = "$DISABLED" ] ; then
                    ENABLE_HIG_STACK="${arg_value,,}"
                else
                    log_message_direct "ERROR: invalid argument value: $arg_value"
                    help
                    exit 2
                fi
                ;;
            *) # unknown option
                log_message_direct "ERROR: Option '${BOLD}$1${NORM} $arg_value' not allowed."
                help
                exit 2
                ;;
        esac

        shift

        if [ $shift_once -eq 0 ] ; then
            shift
        fi

    done
}

# -----------------------------------------------------------------------------
# Install docker-ce package.
# Globals:
#   ENABLED
#   DISABLED
#   MIRROR_DOCKER_PACKAGE_URL
#   OFFICIAL_DOCKER_PACKAGE_URL
#   DOCKER_PACKAGE_LOCAL_PATH
# Arguments:
#   enable_mirror: $ENABLED or $DISABLED
# Returns:
#   None
# -----------------------------------------------------------------------------
function install_docker() {
    local enable_mirror="$1"

    # log function executing
    log_message "executing install docker function with arguments: (enable_mirror = '$enable_mirror')"

    # TODO: replace with following code for AzureChinaCloud
    # curl -fsSL https://mirror.azure.cn/docker-engine/apt/gpg | sudo apt-key add -
    # sudo add-apt-repository "deb [arch=amd64] https://mirror.azure.cn/docker-engine/apt/repo ubuntu-xenial main"
    # sudo apt-get update --fix-missing
    # apt-cache policy docker-engine
    # sudo apt-get install -y unzip docker-engine nginx apache2-utils
    
    # set docker package url
    local docker_package_url
    if [ "$enable_mirror" = "$ENABLED" ] ; then
        docker_package_url="$MIRROR_DOCKER_PACKAGE_URL"
    else
        docker_package_url="$OFFICIAL_DOCKER_PACKAGE_URL"
    fi

    # download docker package from remote
    log_message "downloading docker-ce package from '$docker_package_url' to '$DOCKER_PACKAGE_LOCAL_PATH'"
    curl -o "$DOCKER_PACKAGE_LOCAL_PATH" -L "$docker_package_url"
    log_message "downloaded docker-ce package from '$docker_package_url' to '$DOCKER_PACKAGE_LOCAL_PATH'"

    # install docker package from local
    log_message "installing docker package from '$DOCKER_PACKAGE_LOCAL_PATH'"
    apt-get update

    # workaround to resolve libltdl7 dependency
    {
        dpkg -i "$DOCKER_PACKAGE_LOCAL_PATH"
    } || {
        apt-get -f install -y
    }

    log_message "installed docker package from '$DOCKER_PACKAGE_LOCAL_PATH'"

    # test docker installed
    docker --version

    # log function executed
    log_message "executed install docker function with arguments: (enable_mirror = '$enable_mirror')"
}

# -----------------------------------------------------------------------------
# Install kubectl.
# Globals:
#   KUBECTL_URL
#   KUBECTL_TEMP_PATH
#   KUBECTL_MIRROR_URL
#   KUBECTL_INSTALL_PATH
# Arguments:
#   enable_mirror: $ENABLED or $DISABLED
# Returns:
#   None
# -----------------------------------------------------------------------------
function install_kubectl() {
    local enable_mirror=$1

    # log function executing
    log_message "executing install kubectl function with arguments: (enable_mirror = $enable_mirror)"

    # download kubectl from remote
    if [ "$enable_mirror" = "$ENABLED" ] ; then
        log_message "dowloading kubectl from mirror site '$KUBECTL_MIRROR_URL' to '$KUBECTL_TEMP_PATH'"
        curl -o "$KUBECTL_TEMP_PATH" -L "$KUBECTL_MIRROR_URL"
        log_message "dowloaded kubectl from mirror site '$KUBECTL_MIRROR_URL' to '$KUBECTL_TEMP_PATH'"
    else
        log_message "dowloading kubectl from '$KUBECTL_URL' to '$KUBECTL_TEMP_PATH'"
        curl -o "$KUBECTL_TEMP_PATH" -L "$KUBECTL_URL"
        log_message "dowloaded kubectl from '$KUBECTL_URL' to '$KUBECTL_TEMP_PATH'"
    fi
    
    # install kubectl from local
    log_message "installing kubectl from '$KUBECTL_TEMP_PATH' to '$KUBECTL_INSTALL_PATH'"
    chmod +x "$KUBECTL_TEMP_PATH"
    sudo mv "$KUBECTL_TEMP_PATH" "$KUBECTL_INSTALL_PATH"
    log_message "installed kubectl from '$KUBECTL_TEMP_PATH' to '$KUBECTL_INSTALL_PATH'"

    # test kubectl installed
    kubectl version --client

    # log function executed
    log_message "executed install kubectl function with arguments: (enable_mirror = $enable_mirror)"
}

# -----------------------------------------------------------------------------
# Load kube config.
# Globals:
#   K8S_MASTER_NODE_HOSTNAME
#   K8S_MASTER_NODE_USERNAME
#   K8S_MASTER_NODE_IDENTITY_FILE_BASE64
#   K8S_MASTER_NODE_IDENTITY_FILE_PATH
#   K8S_MASTER_NODE_KUBE_CONFIG_PATH
#   KUBE_CONFIG_LOCAL_DIR
#   KUBE_CONFIG_LOCAL_PATH
# Arguments:
#   None
# Returns:
#   None
# -----------------------------------------------------------------------------
function load_kube_config() {
    # log function executing
    log_message "executing load kube config function"

    # decode kubernetes identity file
    log_message "docoding kubernetes identity file to '$K8S_MASTER_NODE_IDENTITY_FILE_PATH'"

    # base64 decode
    local base64_str="$K8S_MASTER_NODE_IDENTITY_FILE_BASE64"
    echo "$base64_str" | base64 -d | tee "$K8S_MASTER_NODE_IDENTITY_FILE_PATH"

    # set identity file permission
    chmod 400 ${K8S_MASTER_NODE_IDENTITY_FILE_PATH}

    log_message "docoded kubernetes identity file to '$K8S_MASTER_NODE_IDENTITY_FILE_PATH'"

    # load kube config from kubernetes master node
    log_message "loading kube config from '$K8S_MASTER_NODE_HOSTNAME' to '$KUBE_CONFIG_LOCAL_PATH'"

    # prepare kube config directory
    mkdir -p "$KUBE_CONFIG_LOCAL_DIR"

    # download kube config file
    scp -o StrictHostKeyChecking=no -i "$K8S_MASTER_NODE_IDENTITY_FILE_PATH" "$K8S_MASTER_NODE_USERNAME@$K8S_MASTER_NODE_HOSTNAME:$K8S_MASTER_NODE_KUBE_CONFIG_PATH" "$KUBE_CONFIG_LOCAL_PATH"

    log_message "loaded kube config from '$K8S_MASTER_NODE_HOSTNAME' to '$KUBE_CONFIG_LOCAL_PATH'"

    # test kube config loaded

    kubectl get nodes

    # log function executed
    log_message "executed load kube config function"
}

# -----------------------------------------------------------------------------
# Install helm function.
# Globals:
#   ENABLED
#   K8S_NAMESPACE_KUBE_SYSTEM
#   HELM_INSTALL_SCRIPT_LOCAL_PATH
#   HELM_INSTALL_SCRIPT_URL
#   HELM_TILLER_DEPLOYMENT
#   HELM_TILLER_MIRROR_IMAGE
#   HELM_TILLER_VERSION_TAG
# Arguments:
#   enable_mirror: $ENABLED or $DISABLED
# Returns:
#   None
# -----------------------------------------------------------------------------
function install_helm() {
    local enable_mirror=$1

    # log function executing
    log_message "executing install helm function with arguments: (enable_mirror = $enable_mirror)"

    # initialize helm

    if [ "$enable_mirror" = "$ENABLED" ] ; then
        local temp_file="$INSTALL_DIR/$HELM_DIST"
        curl -SsL "$HELM_DOWNLOAD_MIRROR" -o "$temp_file"
        local helm_temp="$INSTALL_DIR/helm"
        mkdir -p "$helm_temp"
        tar xf "$temp_file" -C "$helm_temp"
        cp "$helm_temp/linux-amd64/helm" "/usr/local/bin"
    else
        # download helm install script
        local local_path="$HELM_INSTALL_SCRIPT_LOCAL_PATH"

        log_message "downloading helm install script from '$HELM_INSTALL_SCRIPT_URL' to '$local_path'"

        # download from remote
        curl -o "$local_path" -L "$HELM_INSTALL_SCRIPT_URL"

        # set execution permission
        chmod 700 "$local_path"

        log_message "downloaded helm install script from '$HELM_INSTALL_SCRIPT_URL' to '$local_path'"

        # execute helm install script

        log_message "executing helm install script from '$local_path'"

        bash "$local_path"

        log_message "executed helm install script from '$local_path'"
    fi

    # test helm installed
    helm version

    # log function executed
    log_message "executed write install helm function with arguments: (enable_mirror = $enable_mirror)"
}

# -----------------------------------------------------------------------------
# Download microservice reference architecture project function.
# Globals:
#   MSREF_DOWNLOAD_METHOD
#   HTTP_DIRECT
#   GITHUB_REPO
#   MSREF_HTTP_URL
#   MSREF_HTTP_DOWNLOAD_TEMP_PATH
#   MSREF_LOCAL_PATH
#   MSREF_REPO_ACCOUNT
#   MSREF_REPO_PROJECT
#   MSREF_REPO_BRANCH
# Arguments:
#   None
# Returns:
#   None
# -----------------------------------------------------------------------------
function download_msref() {
    # log function executing
    log_message "executing download msref project function"

    # download msref project directly via http
    if [ "$MSREF_DOWNLOAD_METHOD" = "$HTTP_DIRECT" ] ; then
        local temp_path="$MSREF_HTTP_DOWNLOAD_TEMP_PATH"

        log_message "downloading msref project from '$MSREF_HTTP_URL' to '$temp_path'"
        curl -o "$temp_path" -L "$MSREF_HTTP_URL"
        log_message "downloading msref project from '$MSREF_HTTP_URL' to '$temp_path'"

        log_message "installing unzip package"
        apt-get install unzip -y
        log_message "installed unzip package"

        log_message "decompressing msref project from '$temp_path' to '$MSREF_LOCAL_PATH'"
        unzip -o "$temp_path" -d "$INSTALL_DIR"
        mv "$DEFAULT_MSREF_ZIP_NAME" "$MSREF_LOCAL_PATH"
        log_message "decompressed msref project from '$temp_path' to '$MSREF_LOCAL_PATH'"

    # clone msref project from GitHub repository
    elif [ $MSREF_DOWNLOAD_METHOD = $GITHUB_REPO ] ; then
        local repo_account="$MSREF_REPO_ACCOUNT"
        local repo_project="$MSREF_REPO_PROJECT"
        local repo_url="https://github.com/$repo_account/$repo_project"

        log_message "cloning GitHub msref project from '$repo_url' to '$MSREF_LOCAL_PATH'"
        git clone "$repo_url" -L "$MSREF_LOCAL_PATH"
        log_message "cloned GitHub msref project from '$repo_url' to '$MSREF_LOCAL_PATH'"

        log_message "checking out msref project branch '$MSREF_REPO_BRANCH'"
        pushd . >> /dev/null
        cd $MSREF_LOCAL_PATH
        git checkout "$MSREF_REPO_BRANCH"
        popd . >> /dev/null
        log_message "checked out msref project branch '$MSREF_REPO_BRANCH'"
    fi

    # log function executed
    log_message "executed download msref project function"
}

# -----------------------------------------------------------------------------
# Cleanup old deployment.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
# -----------------------------------------------------------------------------
function cleanup_old_deployment() {
    # log function executing
    log_message "clean up load deployment"

    helm delete --purge $(helm list --namespace "$MONITOR_CLUSTER_NS" -q)
    log_message "helm charts deleted"

    kubectl delete namespace "$MONITOR_CLUSTER_NS"
    log_message "namespace '$MONITOR_CLUSTER_NS' deleted"
}

# -----------------------------------------------------------------------------
# Install helm charts function.
# Globals:
#   ENABLED
#   DISABLED
#   MONITOR_CLUSTER_NS
#   AZURE_CHINA_CLOUD
#   AZURE_CLOUD
#   HELM_CHART_ELK_PATH
#   HELM_CHART_ELK_AZURE_CHINA_CONFIG_PATH
#   HELM_CHART_HEAPSTER_PATH
#   HELM_CHART_HEAPSTER_CONFIG_PATH
#   HELM_CHART_INFLUXDB_PATH
#   HELM_CHART_INFLUXDB_CONFIG_PATH
#   HELM_CHART_GRAFANA_PATH
#   HELM_CHART_GRAFANA_CONFIG_PATH
# Arguments:
#   enable_elk_stack: $ENABLED or $DISABLED
#   enable_hig_stack: $ENABLED or $DISABLED
# Returns:
#   None
# -----------------------------------------------------------------------------
function install_helm_charts() {
    local enable_elk_stack=$1
    local enable_hig_stack=$2

    # log function executing
    log_message "executing install helm charts function with arguments: (enable_elk_stack='$enable_elk_stack', enable_hig_stack='$enable_hig_stack')"

    # create namespace
    if [ "$(kubectl get namespaces | grep '$MONITOR_CLUSTER_NS')" = "" ] ; then
        log_message "creating namespace '$MONITOR_CLUSTER_NS'"
        kubectl create namespace "$MONITOR_CLUSTER_NS"
        log_message "created namespace '$MONITOR_CLUSTER_NS'"
    else
        log_message "ERROR: namespace '$MONITOR_CLUSTER_NS' already exist."
        exit
    fi
    
    # install elk charts
    if [ "$enable_elk_stack" = "$ENABLED" ] ; then
        if [ "$AZURE_CLOUD_ENVIRONMENT" = "$AZURE_CHINA_CLOUD" ] ; then
            # install elk charts to AzureChinaCloud
            local config_path=$HELM_CHART_ELK_AZURE_CHINA_CONFIG_PATH
            log_message "installing elk charts from '$HELM_CHART_ELK_PATH' with config file '$config_path' to namespace '$MONITOR_CLUSTER_NS'"
            helm install -f "$config_path" "$HELM_CHART_ELK_PATH" \
                         --name elk --namespace "$MONITOR_CLUSTER_NS"
            log_message "installed elk charts from '$HELM_CHART_ELK_PATH' with config file '$config_path' to namespace '$MONITOR_CLUSTER_NS'"

            # install heartbeat
            local heartbeat_config_path=$HELM_CHART_HEARTBEAT_CONFIG_PATH
            local heartbeat_config_options_file_path="$HELM_CHARTS_CONFIG_LOCAL_PATH/heartbeat-config/heartbeat.yml"
            local heartbeat_config_options_folder_path="$HELM_CHART_HEARTBEAT_PATH/config"

            # replace namespace in config option file
            sed -i "s#{MONITOR_CLUSTER_NS}#${MONITOR_CLUSTER_NS}#I" $heartbeat_config_options_file_path
             # copy config option file to chart folder
            yes | cp -rf "$heartbeat_config_options_file_path" "$heartbeat_config_options_folder_path"

            log_message "installing heartbeat from '$HELM_CHART_HEARTBEAT_PATH' with config file '$heartbeat_config_path' to namespace '$MONITOR_CLUSTER_NS'"
            helm install -f "$heartbeat_config_path" "$HELM_CHART_HEARTBEAT_PATH" \
                         --name heartbeat --namespace "$MONITOR_CLUSTER_NS"
            log_message "installed heartbeat from '$HELM_CHART_HEARTBEAT_PATH' with config file '$heartbeat_config_path' to namespace '$MONITOR_CLUSTER_NS'"

        else
            # install elk charts to AzureCloud
            log_message "installing elk charts from '$HELM_CHART_ELK_PATH' to namespace '$MONITOR_CLUSTER_NS'"
            helm install "$HELM_CHART_ELK_PATH" --namespace "$MONITOR_CLUSTER_NS"
            log_message "installed elk charts from '$HELM_CHART_ELK_PATH' to namespace '$MONITOR_CLUSTER_NS'"

            #TODO: install heartbeat in AzureCloud environment
        fi
    fi

    # install heapster-influxdb-grafana charts
    if [ "$enable_hig_stack" = "$ENABLED" ] ; then
        
        # replace namespace in config files
        sed -i "s#{MONITOR_CLUSTER_NS}#${MONITOR_CLUSTER_NS}#I" $HELM_CHART_HEAPSTER_CONFIG_PATH
        sed -i "s#{MONITOR_CLUSTER_NS}#${MONITOR_CLUSTER_NS}#I" $HELM_CHART_GRAFANA_CONFIG_PATH

        # TODO: support AzureCloud environment

        # install heapster chart to AzureChinaCloud
        log_message "installing heapster chart from '$HELM_CHART_HEAPSTER_PATH' with config file '$HELM_CHART_HEAPSTER_CONFIG_PATH' to namespace '$MONITOR_CLUSTER_NS'"
        helm install -f "$HELM_CHART_HEAPSTER_CONFIG_PATH" "$HELM_CHART_HEAPSTER_PATH" \
                     --name heapster --namespace "$MONITOR_CLUSTER_NS"
        log_message "installed heapster chart from '$HELM_CHART_HEAPSTER_PATH' with config file '$HELM_CHART_HEAPSTER_CONFIG_PATH' to namespace '$MONITOR_CLUSTER_NS'"

        # install influxdb chart to AzureChinaCloud
        log_message "installing influxdb chart from '$HELM_CHART_INFLUXDB_PATH' with config file '$HELM_CHART_INFLUXDB_CONFIG_PATH' to namespace '$MONITOR_CLUSTER_NS'"
        helm install -f "$HELM_CHART_INFLUXDB_CONFIG_PATH" "$HELM_CHART_INFLUXDB_PATH" \
                     --name influxdb --namespace "$MONITOR_CLUSTER_NS"
        log_message "installed influxdb chart from '$HELM_CHART_INFLUXDB_PATH' with config file '$HELM_CHART_INFLUXDB_CONFIG_PATH' to namespace '$MONITOR_CLUSTER_NS'"

        # install grafana chart to AzureChinaCloud
        log_message "installing grafana chart from '$HELM_CHART_GRAFANA_PATH' with config file '$HELM_CHART_GRAFANA_CONFIG_PATH' to namespace '$MONITOR_CLUSTER_NS'"
        helm install -f "$HELM_CHART_GRAFANA_CONFIG_PATH" "$HELM_CHART_GRAFANA_PATH" \
                     --name grafana --namespace "$MONITOR_CLUSTER_NS"
        log_message "installed grafana chart from '$HELM_CHART_GRAFANA_PATH' with config file '$HELM_CHART_GRAFANA_CONFIG_PATH' to namespace '$MONITOR_CLUSTER_NS'"
    fi

    # log function executed
    log_message "executed install helm charts function with arguments: (enable_elk_stack='$enable_elk_stack', enable_hig_stack='$enable_hig_stack')"
}

# -----------------------------------------------------------------------------
# Write cleanup script function.
# Globals:
#   CLEANUP_SCRIPT_PATH
#   INSTALL_DIR
#   KUBECTL_INSTALL_PATH
#   KUBE_CONFIG_LOCAL_DIR
# Arguments:
#   None
# Returns:
#   None
# -----------------------------------------------------------------------------
function write_cleanup_script() {
    # log function executing
    log_message "executing write cleanup script function"

    # TODO: load content from remote
    local cleanup_script_content="#!/usr/bin/env bash
# clean helm charts
helm delete --purge \$(helm list --namespace "$MONITOR_CLUSTER_NS" -q)

# clean helm
helm reset
rm -r /root/.helm
rm -f /usr/local/bin/helm

# clean kubectl
rm -r $KUBE_CONFIG_LOCAL_DIR
rm -f $KUBECTL_INSTALL_PATH

# clean docker
apt-get purge docker-engine -y
apt-get autoremove -y

# stop kube ui proxy
kill $(pgrep -f "kubectl proxy")

# clean nginx
apt-get purge nginx apache2-utils -y
apt-get autoremove -y

# clean temp directory
rm -r $INSTALL_DIR"

    log_message "writing cleanup script content: '$cleanup_script_content' to '$CLEANUP_SCRIPT_PATH'"

    # write cleanup script file
    echo -e "$cleanup_script_content" > "$CLEANUP_SCRIPT_PATH"

    log_message "wrote cleanup script content to '$CLEANUP_SCRIPT_PATH'"

    # log function executed
    log_message "executed write cleanup script function"
}

# -----------------------------------------------------------------------------
# Set feature flags function.
# Globals:
#   ENABLED
#   DISABLED
#   AZURE_CLOUD
#   AZURE_CHINA_CLOUD
#   ENABLE_DOCKER_PACKAGE_MIRROR_FLAG
#   ENABLE_KUBECTL_MIRROR_FLAG
#   ENABLE_HELM_TILLER_IMAGE_MIRROR_FLAG
# Arguments:
#   azure_cloud_env: $AZURE_CLOUD or $AZURE_CHINA_CLOUD
# Returns:
#   None
# -----------------------------------------------------------------------------
function set_feature_flags() {
    local azure_cloud_env=$1

    # log function executing
    log_message "executing set feature flags function with arguments: (azure_cloud_env=$azure_cloud_env)"

    if [ "$azure_cloud_env" = "$AZURE_CLOUD" ] ; then
        # disable mirror flags for AzureCloud
        ENABLE_DOCKER_PACKAGE_MIRROR_FLAG="$DISABLED"
        ENABLE_KUBECTL_MIRROR_FLAG="$DISABLED"
        ENABLE_HELM_TILLER_IMAGE_MIRROR_FLAG="$DISABLED"
    elif [ "$azure_cloud_env" = "$AZURE_CHINA_CLOUD" ] ; then
        # enable mirror flags for AzureChinaCloud
        ENABLE_DOCKER_PACKAGE_MIRROR_FLAG="$ENABLED"
        ENABLE_KUBECTL_MIRROR_FLAG="$ENABLED"
        ENABLE_HELM_TILLER_IMAGE_MIRROR_FLAG="$ENABLED"
    fi

    # log function executed
    log_message "executed set feature flags function with arguments: (azure_cloud_env=$azure_cloud_env)"
}

# -----------------------------------------------------------------------------
# Setup nginx function.
# Globals:
#   K8S_UI_ADMIN_USERNAME
#   K8S_UI_ADMIN_PASSWORD
#   MSREF_NGINX_SITE_CONFIG_PATH
#   NGINX_DEFAULT_SITE_PATH
#   KUBE_PROXY_LOG_FILE
# Arguments:
#   None
# Returns:
#   None
# -----------------------------------------------------------------------------
function setup_nginx() {
    # log function executing
    log_message "executing setup nginx function"

    # install nginx and apach2-utils packages
    log_message "installing nginx and apache2-utils packages"
    apt-get install nginx apache2-utils -y
    log_message "installed nginx and apache2-utils packages"

    # set admin password
    local admin_user="$K8S_UI_ADMIN_USERNAME"
    local admin_pass="$K8S_UI_ADMIN_PASSWORD"
    log_message "setting ui admin user password in nginx"
    echo "$admin_pass" | htpasswd -c -i /etc/nginx/.htpasswd "$admin_user"
    log_message "set ui admin user password in nginx"

    # copy nginx site config to default site
    log_message "copying nginx site config to default site"
    cp "$MSREF_NGINX_SITE_CONFIG_PATH" "$NGINX_DEFAULT_SITE_PATH"
    log_message "copied nginx site config to default site"

    # set proxy from local port 8080 to kubenetes dashboard
    log_message "setting proxy from local port 8080 to kubenetes dashboard"
    nohup kubectl proxy --port=8080 > "$KUBE_PROXY_LOG_FILE" 2>&1 &
    log_message "set proxy from local port 8080 to kubenetes dashboard"

    # activate nginx config
    log_message "activating nginx config"
    systemctl reload nginx
    log_message "activated nginx config"

    # test nginx
    sleep 10
    curl http://localhost/ -u "$admin_user:$admin_pass"

    # log function executed
    log_message "executed setup nginx function"
}

# -----------------------------------------------------------------------------
# Main entry function.
# Globals:
#   AZURE_CLOUD_ENVIRONMENT
#   ENABLE_DOCKER_PACKAGE_MIRROR_FLAG
#   ENABLE_KUBECTL_MIRROR_FLAG
#   ENABLE_HELM_TILLER_IMAGE_MIRROR_FLAG
#   ENABLE_ELK_STACK
#   ENABLE_HIG_STACK
#   CLEANUP_SCRIPT_PATH
#   LOG_FILE
# Arguments:
#   None
# Returns:
#   None
# -----------------------------------------------------------------------------
function main() {
    # log main function executing
    log_message "executing main function"

    # write cleanup script
    write_cleanup_script

    # set feature flags
    set_feature_flags "$AZURE_CLOUD_ENVIRONMENT"

    {
        # install docker-ce package
        install_docker "$ENABLE_DOCKER_PACKAGE_MIRROR_FLAG"

        # install kubectl
        install_kubectl "$ENABLE_KUBECTL_MIRROR_FLAG"

        # load kube config
        load_kube_config

        # install helm
        install_helm "$ENABLE_HELM_MIRROR_FLAG"

        # download msref project
        download_msref

        # setup nginx
        setup_nginx 2>&1 | tee -a $LOG_FILE

        # cleanup old deployment
        cleanup_old_deployment

        # install helm charts
        install_helm_charts "$ENABLE_ELK_STACK" "$ENABLE_HIG_STACK"
    } || {
        log_message "config failed"
    }

    log_message "cleanup command: bash $CLEANUP_SCRIPT_PATH"

    echo "view log command: cat $LOG_FILE"

    # log main function executed
    log_message "executed main function"
}

# =============================================================================
# Start Execution
# =============================================================================

# prepare install directory
mkdir -p "$INSTALL_DIR"

log_message_direct "Script version: $SCRIPT_VERSION"

log_message_direct "Controller VM configuration starting with args: $@"

log_message_direct "Install directory: $INSTALL_DIR"

# parse command line arguments
parse_args $@

if [ "$K8S_MASTER_NODE_HOSTNAME" = "" ] || \
   [ "$K8S_MASTER_NODE_USERNAME" = "" ] || \
   [ "$K8S_MASTER_NODE_IDENTITY_FILE_BASE64" = "" ] || \
   [ "$K8S_UI_ADMIN_USERNAME" = "" ] || \
   [ "$K8S_UI_ADMIN_PASSWORD" = ""] ; then
    log_message_direct "ERROR: Missing required arguments."
    # missing required arguments, print help hints
    help
    exit
else
    # Invoke main entry function.
    main 2>&1 | tee -a $LOG_FILE
fi

log_message_direct "Controller VM configuration completed."