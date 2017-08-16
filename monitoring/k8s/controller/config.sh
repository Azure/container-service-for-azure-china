#!/usr/bin/env bash
#
# Config controller VM environments.
#
# Usages:
#
# For Public Azure Environment:
# bash config.sh --k8s-master-node-hostname="<K8S_MASTER_NODE_HOSTNAME>" \
#                --k8s-master-node-username="<K8S_MASTER_NODE_USERNAME>" \
#                --k8s-master-node-id-file-base64="<K8S_MASTER_NODE_IDENTITY_FILE_BASE64>"
#
# For Azure China Environment:
# bash config.sh --azure-cloud-env="AzureChinaCloud" \
#                --k8s-master-node-hostname="<K8S_MASTER_NODE_HOSTNAME>" \
#                --k8s-master-node-username="<K8S_MASTER_NODE_USERNAME>" \
#                --k8s-master-node-id-file-base64="<K8S_MASTER_NODE_IDENTITY_FILE_BASE64>"
#

set -e

# =============================================================================
# feature flags, could change on demand.
# =============================================================================

# enable feature flag
readonly ENABLED="enabled"

# disable feature flag
readonly DISABLED="disabled"

# flag to enable docker package mirror or not.
ENABLE_DOCKER_PACKAGE_MIRROR_FLAG="$ENABLED"

# flag to enable kubectl mirror or not.
ENABLE_KUBECTL_MIRROR_FLAG="$ENABLED"

# flag to enable helm tiller image mirror or not
ENABLE_HELM_TILLER_IMAGE_MIRROR_FLAG="$ENABLED"

# =============================================================================
# constants
# =============================================================================

# azure environments
readonly AZURE_CLOUD="AzureCloud"
readonly AZURE_CHINA_CLOUD="AzureChinaCloud"

# install directory
readonly INSTALL_DIR="/root/tmp/install"

# log file
readonly LOG_FILE="$INSTALL_DIR/config.log"

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
# TODO: replace to an official mirror site
readonly KUBECTL_MIRROR_URL="https://ccgmsref.blob.core.windows.net/mirror/kubectl" 
readonly KUBECTL_TEMP_PATH="$INSTALL_DIR/kubectl"
readonly KUBECTL_INSTALL_PATH="/usr/local/bin/kubectl"

# kubenetes constants
readonly K8S_MASTER_NODE_IDENTITY_FILE_PATH="$INSTALL_DIR/k8s_id"
readonly K8S_MASTER_NODE_KUBE_CONFIG_PATH="~/.kube/config"
readonly K8S_NAMESPACE_KUBE_SYSTEM="kube-system"

# kube config constants
readonly KUBE_CONFIG_LOCAL_DIR="/root/.kube"
readonly KUBE_CONFIG_LOCAL_PATH="$KUBE_CONFIG_LOCAL_DIR/config"

# helm contstants
readonly HELM_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get"
readonly HELM_INSTALL_SCRIPT_LOCAL_PATH="$INSTALL_DIR/install_helm.sh"
readonly HELM_TILLER_DEPLOYMENT="deployments/tiller-deploy"
readonly HELM_TILLER_VERSION_TAG="$(curl -SsL https://github.com/kubernetes/helm/releases/latest | awk '/\/tag\//' | head -n 1 | cut -d '"' -f 2 | awk '{n=split($NF,a,"/");print a[n]}')"
readonly HELM_TILLER_MIRROR_IMAGE="crproxy.trafficmanager.net:6000/kubernetes-helm/tiller"

# microservice reference architecture project constants
readonly GITHUB_REPO="GIT" # download from GitHub repo
readonly HTTP_DIRECT="HTTP" # download zip package directly via HTTP
readonly MSREF_LOCAL_PATH="$INSTALL_DIR/msref"
readonly MSREF_HTTP_DOWNLOAD_TEMP_PATH="$INSTALL_DIR/msref.zip"

# helm charts constants
readonly HELM_CHARTS_LOCAL_PATH="$MSREF_LOCAL_PATH/monitoring/k8s/helm-charts"
readonly HELM_CHARTS_CONFIG_LOCAL_PATH="$MSREF_LOCAL_PATH/monitoring/k8s/helm-charts/configs"
readonly HELM_CHART_ELK_PATH="$HELM_CHARTS_LOCAL_PATH/elk"
readonly HELM_CHART_INFLUXDB_PATH="$HELM_CHARTS_LOCAL_PATH/influxdb"
readonly HELM_CHART_HEAPSTER_PATH="$HELM_CHARTS_LOCAL_PATH/heapster"
readonly HELM_CHART_GRAFANA_PATH="$HELM_CHARTS_LOCAL_PATH/grafana"

# =============================================================================
# command line arguments
# =============================================================================

# options
readonly ARG_HELP="--help"
readonly ARG_HELP_ALIAS="-h"
readonly ARG_K8S_MASTER_NODE_HOSTNAME="--k8s-master-node-hostname"
readonly ARG_K8S_MASTER_NODE_USERNAME="--k8s-master-node-username"
readonly ARG_K8S_MASTER_NODE_IDENTITY_FILE_BASE64="--k8s-master-node-id-file-base64"
readonly ARG_MONITOR_CLUSTER_NS="--monitor-cluster-ns"
readonly ARG_AZURE_CLOUD_ENVIRONMENT="--azure-cloud-env"
readonly ARG_MSREF_DOWNLOAD_METHOD="--msref-download-method"
readonly ARG_MSREF_HTTP_URL="--maref-http-url"
readonly ARG_MSREF_REPO_ACCOUNT="--msref-repo-account"
readonly ARG_MSREF_REPO_PROJECT="--msref-repo-project"
readonly ARG_MSREF_REPO_BRANCH="--maref-repo-branch"

# default values
readonly DEFAULT_MONITOR_CLUSTER_NS="monitor-cluster-ns"
readonly DEFAULT_AZURE_CLOUD_ENVIRONMENT="$AZURE_CLOUD"
readonly DEFAULT_MSREF_DOWNLOAD_METHOD="$HTTP_DIRECT"
readonly DEFAULT_MSREF_HTTP_URL="https://ccgmsref.blob.core.windows.net/release/msref.zip"
readonly DEFAULT_MSREF_REPO_ACCOUNT="Azure"
readonly DEFAULT_MSREF_REPO_PROJECT="microservice-reference-architectures"
readonly DEFAULT_MSREF_REPO_BRANCH="master"

# variables
K8S_MASTER_NODE_HOSTNAME=""
K8S_MASTER_NODE_USERNAME=""
K8S_MASTER_NODE_IDENTITY_FILE_BASE64=""
MONITOR_CLUSTER_NS="$DEFAULT_MONITOR_CLUSTER_NS"
AZURE_CLOUD_ENVIRONMENT="$DEFAULT_AZURE_CLOUD_ENVIRONMENT"
MSREF_DOWNLOAD_METHOD="$DEFAULT_MSREF_DOWNLOAD_METHOD"
MSREF_HTTP_URL="$DEFAULT_MSREF_HTTP_URL"
MSREF_REPO_ACCOUNT="$DEFAULT_MSREF_REPO_ACCOUNT"
MSREF_REPO_PROJECT="$DEFAULT_MSREF_REPO_PROJECT"
MSREF_REPO_BRANCH="$DEFAULT_MSREF_REPO_BRANCH"

# =============================================================================
# functions
# =============================================================================

# -----------------------------------------------------------------------------
# Help function.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
# -----------------------------------------------------------------------------
function help() {
  echo "This script is used to config controller VM environments"
  echo "options:"
  echo "	--help or -h: help hints"
  echo "	--k8s-master-node-hostname: required, kubernetes cluster master node hostname"
  echo "	--k8s-master-node-username: required, kubernetes cluster master node username"
  echo "	--k8s-master-node-id-file-base64: required, kubernetes cluster master node identity file in base64 encoded string"
  echo "	--monitor-cluster-ns: optional, monitoring cluster namespace in kubernetes, default value: 'monitor-cluster-ns'"
  echo "	--azure-cloud-env: optional, azure cloud environment '$AZURE_CLOUD' or '$AZURE_CHINA_CLOUD', default value: '$DEFAULT_AZURE_CLOUD_ENVIRONMENT'"
  echo "	--msref-download-method: optional, microservice reference architecture download method '$HTTP_DIRECT' or '$GITHUB_REPO', default value: '$DEFAULT_MSREF_DOWNLOAD_METHOD'"
  echo "	--maref-http-url: optional, microservice reference architecture http download url, default value: '$DEFAULT_MSREF_HTTP_URL'"
  echo "	--msref-repo-account: optional, microservice reference architecture GitHub repo account name, default value: '$DEFAULT_MSREF_REPO_ACCOUNT'"
  echo "	--msref-repo-project: optional, microservice reference architecture GitHub repo project name, default value: '$DEFAULT_MSREF_REPO_PROJECT'"
  echo "	--maref-repo-branch: optional, microservice reference architecture GitHub repo project branch, default value: '$DEFAULT_MSREF_REPO_BRANCH'"
}

# -----------------------------------------------------------------------------
# Log message.
# Globals:
#   None
# Arguments:
#   message
# Returns:
#   None
# -----------------------------------------------------------------------------
function log_message() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") $1" | tee -a $LOG_FILE
}

# -----------------------------------------------------------------------------
# Parse command line arguments function.
# Globals:
#   ARG_K8S_MASTER_NODE_HOSTNAME
#   ARG_K8S_MASTER_NODE_USERNAME
#   ARG_K8S_MASTER_NODE_IDENTITY_FILE_BASE64
#   K8S_MASTER_NODE_HOSTNAME
#   K8S_MASTER_NODE_USERNAME
#   K8S_MASTER_NODE_IDENTITY_FILE_BASE64
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

    log_message "Option '${1}' set with value '"$arg_value"'"

    case "$1" in
      $ARG_HELP_ALIAS, $ARG_HELP)
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
      $ARG_MONITOR_CLUSTER_NS)
        MONITOR_CLUSTER_NS="$arg_value"
        ;;
      $ARG_AZURE_CLOUD_ENVIRONMENT)
        if [ "$arg_value" = "$AZURE_CLOUD" ] || \
           [ "$arg_value" = "$AZURE_CHINA_CLOUD" ] ; then
          AZURE_CLOUD_ENVIRONMENT="$arg_value"
        else
          log_message "invalid argument value: $arg_value"
          help
          exit 2
        fi
        ;;
      $ARG_MSREF_DOWNLOAD_METHOD)
        if [ "$arg_value" = "$HTTP_DIRECT" ] || \
           [ "$arg_value" = "$GITHUB_REPO" ] ; then
          MSREF_DOWNLOAD_METHOD="$arg_value"
        else
          log_message "invalid argument value: $arg_value"
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
#   enable_mirror: ENABLED or DISABLED
# Returns:
#   None
# -----------------------------------------------------------------------------
function install_docker() {
    local enable_mirror="$1"

    # log function executing
    log_message "executing install docker function with arguments: (enable_mirror = '$enable_mirror')"
    
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
#   enable_mirror
# Returns:
#   None
# -----------------------------------------------------------------------------
function install_kubectl() {
    local enable_mirror=$1

    # log function executing
    log_message "executing install kubectl function with arguments: (enable_mirror = $enable_mirror)"

    # download kubectl from remote
    
    if [ "$enable_mirror" = "$ENABLED" ] ; then
        log_message "dowloading kubectl from '$KUBECTL_MIRROR_URL' to '$KUBECTL_TEMP_PATH'"

        curl -o "$KUBECTL_TEMP_PATH" -L "$KUBECTL_MIRROR_URL"

        log_message "dowloaded kubectl from '$KUBECTL_MIRROR_URL' to '$KUBECTL_TEMP_PATH'"
    else
        log_message "dowloading kubectl from '$KUBECTL_URL' to '$KUBECTL_TEMP_PATH'"

        curl -o "$KUBECTL_TEMP_PATH" -L "$KUBECTL_URL"

        log_message "dowloaded kubectl from '$KUBECTL_URL' to '$KUBECTL_TEMP_PATH'"
    fi
    
    # install kubectl from local
    log_message "installing kubectl from '$KUBECTL_TEMP_PATH' to '$KUBECTL_INSTALL_PATH'"

    sudo mv "$KUBECTL_TEMP_PATH" "$KUBECTL_INSTALL_PATH"
    chmod +x "$KUBECTL_INSTALL_PATH"

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
    echo "$K8S_MASTER_NODE_IDENTITY_FILE_BASE64" | base64 -d | tee "$K8S_MASTER_NODE_IDENTITY_FILE_PATH"

    # set identity file permission
    chmod 400 ${K8S_MASTER_NODE_IDENTITY_FILE_PATH}

    log_message "docoded kubernetes identity file to '$K8S_MASTER_NODE_IDENTITY_FILE_PATH'"

    # load kube config from kubernetes master node
    log_message "loading kube config from '$K8S_MASTER_NODE_HOSTNAME' to '$KUBE_CONFIG_LOCAL_PATH'"

    # prepare kube config directory
    mkdir -p "$KUBE_CONFIG_LOCAL_DIR"

    # download kube config file
    scp -o StrictHostKeyChecking=no \
    -i "$K8S_MASTER_NODE_IDENTITY_FILE_PATH" \
    "$K8S_MASTER_NODE_USERNAME@$K8S_MASTER_NODE_HOSTNAME:$K8S_MASTER_NODE_KUBE_CONFIG_PATH" \
    "$KUBE_CONFIG_LOCAL_PATH"

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
#   enable_mirror: ENABLED or DISABLED
# Returns:
#   None
# -----------------------------------------------------------------------------
function install_helm() {
    local enable_mirror=$1

    # log function executing
    log_message "executing install helm function with arguments: (enable_mirror = $enable_mirror)"

    # download helm install script

    log_message "downloading helm install script from '$HELM_INSTALL_SCRIPT_URL' to '$HELM_INSTALL_SCRIPT_LOCAL_PATH'"

    # download from remote
    curl -o "$HELM_INSTALL_SCRIPT_LOCAL_PATH" -L "$HELM_INSTALL_SCRIPT_URL"

    # set execution permission
    chmod 700 "$HELM_INSTALL_SCRIPT_LOCAL_PATH"

    log_message "downloaded helm install script from '$HELM_INSTALL_SCRIPT_URL' to '$HELM_INSTALL_SCRIPT_LOCAL_PATH'"

    # execute helm install script

    log_message "executing helm install script from '$HELM_INSTALL_SCRIPT_LOCAL_PATH'"

    bash "$HELM_INSTALL_SCRIPT_LOCAL_PATH"

    log_message "executed helm install script from '$HELM_INSTALL_SCRIPT_LOCAL_PATH'"

    # initialize helm

    log_message "initializing helm"

    {
        helm init
    } || {
        echo "helm init failed."
    }

    log_message "initialized helm"

    # workaround to resolve tiller image issue
    if [ "$enable_mirror" = "$ENABLED" ] ; then
        # replace failed tiller image with mirror image

        log_message "deploying tiller image from mirror '$HELM_TILLER_MIRROR_IMAGE:$HELM_TILLER_VERSION_TAG' to deployment '$HELM_TILLER_DEPLOYMENT' in namespace '$K8S_NAMESPACE_KUBE_SYSTEM'"

        kubectl --namespace="$K8S_NAMESPACE_KUBE_SYSTEM" \
        set image "$HELM_TILLER_DEPLOYMENT" \
        tiller="$HELM_TILLER_MIRROR_IMAGE:$HELM_TILLER_VERSION_TAG"

        log_message "deployed tiller image from mirror '$HELM_TILLER_MIRROR_IMAGE:$HELM_TILLER_VERSION_TAG'"

        # sleep 10 seconds, wait tiller image up
        sleep 10
    fi

    # test helm installed
    helm version

    # log function executed
    log_message "executed write install helm function with arguments: (enable_mirror = $enable_mirror)"
}

# -----------------------------------------------------------------------------
# Download microservice reference architecture project function.
# Globals:
#   None
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

        log_message "downloading msref project from '$MSREF_HTTP_URL' to '$MSREF_HTTP_DOWNLOAD_TEMP_PATH'"
        curl -o "$MSREF_HTTP_DOWNLOAD_TEMP_PATH" -L "$MSREF_HTTP_URL"
        log_message "downloading msref project from '$MSREF_HTTP_URL' to '$MSREF_HTTP_DOWNLOAD_TEMP_PATH'"

        log_message "installing unzip package"
        apt-get install unzip -y
        log_message "installed unzip package"

        log_message "decompressing msref project from '$MSREF_HTTP_DOWNLOAD_TEMP_PATH' to '$MSREF_LOCAL_PATH'"
        unzip -o "$MSREF_HTTP_DOWNLOAD_TEMP_PATH" -d "$MSREF_LOCAL_PATH"
        log_message "decompressed msref project from '$MSREF_HTTP_DOWNLOAD_TEMP_PATH' to '$MSREF_LOCAL_PATH'"

    # clone msref project from GitHub repository
    elif [ $MSREF_DOWNLOAD_METHOD = $GITHUB_REPO ] ; then

        repo_url="https://github.com/$MSREF_REPO_ACCOUNT/$MSREF_REPO_PROJECT"

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
#   INSTALL_DIR
#   ENABLE_DOCKER_PACKAGE_MIRROR_FLAG
# Arguments:
#   None
# Returns:
#   None
# -----------------------------------------------------------------------------
function set_feature_flags() {
    azure_cloud_env=$1

    if [ "$azure_cloud_env" = "$AZURE_CLOUD" ] ; then
        ENABLE_DOCKER_PACKAGE_MIRROR_FLAG="$DISABLED"
        ENABLE_KUBECTL_MIRROR_FLAG="$DISABLED"
        ENABLE_HELM_TILLER_IMAGE_MIRROR_FLAG="$DISABLED"
    elif [ "$azure_cloud_env" = "$AZURE_CHINA_CLOUD" ] ; then
        ENABLE_DOCKER_PACKAGE_MIRROR_FLAG="$ENABLED"
        ENABLE_KUBECTL_MIRROR_FLAG="$ENABLED"
        ENABLE_HELM_TILLER_IMAGE_MIRROR_FLAG="$ENABLED"
    fi
}

# -----------------------------------------------------------------------------
# Main entry function.
# Globals:
#   INSTALL_DIR
#   ENABLE_DOCKER_PACKAGE_MIRROR_FLAG
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
        install_helm "$ENABLE_HELM_TILLER_IMAGE_MIRROR_FLAG"

        # download msref project
        download_msref

        
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

log_message "Controller VM configuration starting with args: $@"

# parse command line arguments
parse_args $@

if [ "$K8S_MASTER_NODE_HOSTNAME" = "" ] || \
   [ "$K8S_MASTER_NODE_USERNAME" = "" ] || \
   [ "$K8S_MASTER_NODE_IDENTITY_FILE_BASE64" = "" ] ; then
    log_message "ERROR: Missing required arguments."
    # missing required arguments, print help hints
    help
else
    # Invoke main entry function.
    main
fi

log_message "Controller VM configuration completed."