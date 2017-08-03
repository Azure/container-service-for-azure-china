#!/usr/bin/env bash
#
# Config controller VM environments.
set -e

# =============================================================================
# command arguments
# usages:
#   $1: kubernetes master node hostname
#   $2: kubernetes master node username
#   $3: kubernetes master node identity file (based64 encoded)
# =============================================================================
K8S_MASTER_NODE_HOSTNAME=$1
K8S_MASTER_NODE_USERNAME=$2
K8S_MASTER_NODE_IDENTITY_FILE_BASE64=$3

# =============================================================================
# feature flags, could change on demand.
# =============================================================================

# enable feature flag
readonly ENABLED="enabled"

# disable feature flag
readonly DISABLED="disabled"

# flag to enable docker package mirror or not.
readonly ENABLE_DOCKER_PACKAGE_MIRROR_FLAG="$ENABLED"

# =============================================================================
# constants
# =============================================================================

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
readonly KUBECTL_TEMP_PATH="$INSTALL_DIR/kubectl"
readonly KUBECTL_INSTALL_PATH="/usr/local/bin/kubectl"

# kubenetes constants
readonly K8S_MASTER_NODE_IDENTITY_FILE_PATH="$INSTALL_DIR/k8s_id"
readonly K8S_MASTER_NODE_KUBE_CONFIG_PATH="~/.kube/config"

# kube config constants
readonly KUBE_CONFIG_LOCAL_DIR="/root/.kube"
readonly KUBE_CONFIG_LOCAL_PATH="$KUBE_CONFIG_LOCAL_DIR/config"

# =============================================================================
# functions
# =============================================================================

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
    curl -o "$DOCKER_PACKAGE_LOCAL_PATH" -O "$docker_package_url"
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
#   KUBECTL_INSTALL_PATH
# Arguments:
#   None
# Returns:
#   None
# -----------------------------------------------------------------------------
function install_kubectl() {
    # log function executing
    log_message "executing install kubectl function"

    # download kubectl from remote
    log_message "dowloading kubectl from '$KUBECTL_URL' to '$KUBECTL_TEMP_PATH'"

    curl -o "$KUBECTL_TEMP_PATH" -O "$KUBECTL_URL" 

    log_message "dowloaded kubectl from '$KUBECTL_URL' to '$KUBECTL_TEMP_PATH'"
    
    # install kubectl from local
    log_message "installing kubectl from '$KUBECTL_TEMP_PATH' to '$KUBECTL_INSTALL_PATH'"

    sudo mv "$KUBECTL_TEMP_PATH" "$KUBECTL_INSTALL_PATH"
    chmod +x "$KUBECTL_INSTALL_PATH"

    log_message "installed kubectl from '$KUBECTL_TEMP_PATH' to '$KUBECTL_INSTALL_PATH'"

    # test kubectl installed
    kubectl version --client

    # log function executed
    log_message "executed install kubectl function"
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
apt-get purge docker-engine -y
apt-get autoremove -y
rm $KUBECTL_INSTALL_PATH
rm -r $KUBE_CONFIG_LOCAL_DIR
rm -r $INSTALL_DIR"

    log_message "writing cleanup script content: '$cleanup_script_content' to '$CLEANUP_SCRIPT_PATH'"

    # write cleanup script file
    echo -e "$cleanup_script_content" > "$CLEANUP_SCRIPT_PATH"

    log_message "wrote cleanup script content to '$CLEANUP_SCRIPT_PATH'"

    # log function executed
    log_message "executed write cleanup script function"
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

    {
        # install docker-ce package
        install_docker "$ENABLE_DOCKER_PACKAGE_MIRROR_FLAG"

        # install kubectl
        install_kubectl

        # load kube config
        load_kube_config
    } || {
        log_message "config failed"
    }

    log_message "cleanup command: bash $CLEANUP_SCRIPT_PATH"

    echo "view log command: cat $LOG_FILE"

    # log main function executed
    log_message "executed main function"
}

# =============================================================================
# scripts
# =============================================================================

# prepare install directory
mkdir -p "$INSTALL_DIR"

log_message "Controller VM configuration starting."

# Invoke main entry function.
main

log_message "Controller VM configuration completed."