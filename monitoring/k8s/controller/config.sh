#!/usr/bin/env bash
#
# Config controller VM environments.
set -e

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

# docker package constants
readonly OFFICIAL_DOCKER_PACKAGE_URL="https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_17.06.0~ce-0~ubuntu_amd64.deb"
readonly MIRROR_DOCKER_PACKAGE_URL="https://mirror.azure.cn/docker-engine/apt/repo/pool/main/d/docker-engine/docker-engine_17.05.0~ce-0~ubuntu-xenial_amd64.deb"
readonly DOCKER_PACKAGE_NAME="docker-ce.deb"

# kubectl constants
readonly KUBECTL_VERSION="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
readonly KUBECTL_URL="https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
readonly KUBECTL_INSTALL_PATH="/usr/local/bin/kubectl"

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
    echo "$(date "+%Y-%m-%d %H:%M:%S") $1" | tee $LOG_FILE
}

# -----------------------------------------------------------------------------
# Install docker-ce package.
# Globals:
#   ENABLED
#   DISABLED
#   MIRROR_DOCKER_PACKAGE_URL
#   OFFICIAL_DOCKER_PACKAGE_URL
# Arguments:
#   enable_mirror: ENABLED or DISABLED
# Returns:
#   None
# -----------------------------------------------------------------------------
function install_docker() {
    # log function executing
    log_message "executing install docker function with arguments: (enable_mirror = '$1')"
    
    # set docker package url
    local enable_mirror="$1"
    local docker_package_url
    if [ "$enable_mirror" = "$ENABLED" ] ; then
        docker_package_url="$MIRROR_DOCKER_PACKAGE_URL"
    else
        docker_package_url="$OFFICIAL_DOCKER_PACKAGE_URL"
    fi

    # download docker package from remote
    local local_package_path="$INSTALL_DIR/$DOCKER_PACKAGE_NAME"
    log_message "downloading docker-ce package from '$docker_package_url' to '$local_package_path'"
    curl -o "$local_package_path" -O "$docker_package_url"
    log_message "downloaded docker-ce package from '$docker_package_url' to '$local_package_path'"

    # install docker package from local
    log_message "installing docker package from '$local_package_path'"
    apt-get update

    # workaround to resolve libltdl7 dependency
    {
        dpkg -i "$local_package_path"
    } || {
        apt-get -f install -y
    }

    log_message "installed docker package from '$local_package_path'"

    # log function executed
    log_message "executed install docker function with arguments: (enable_mirror = '$1')"
}

# -----------------------------------------------------------------------------
# Install kubectl.
# Globals:
#   INSTALL_DIR
#   KUBECTL_URL
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
    local kubectl_temp_path="$INSTALL_DIR/kubectl"
    log_message "dowloading kubectl from '$KUBECTL_URL' to '$kubectl_temp_path'"
    curl -o "$kubectl_temp_path" -O "$KUBECTL_URL" 
    log_message "dowloaded kubectl from '$KUBECTL_URL' to '$kubectl_temp_path'"
    
    # install kubectl from local
    log_message "installing kubectl from '$kubectl_temp_path' to '$KUBECTL_INSTALL_PATH'"
    sudo mv "$kubectl_temp_path" "$KUBECTL_INSTALL_PATH"
    chmod +x "$KUBECTL_INSTALL_PATH"
    log_message "installed kubectl from '$kubectl_temp_path' to '$KUBECTL_INSTALL_PATH'"

    # log function executed
    log_message "executed install kubectl function"
}

# -----------------------------------------------------------------------------
# Write cleanup script function.
# Globals:
#   INSTALL_DIR
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
rm $KUBECTL_INSTALL_PATH"

    local cleanup_script_path="$INSTALL_DIR/cleanup.sh"

    log_message "writing cleanup script content: '$cleanup_script_content' to '$cleanup_script_path'"

    echo -e "$cleanup_script_content" > "$cleanup_script_path"

    log_message "wrote cleanup script content to '$cleanup_script_path'"

    echo "cleanup command: bash $cleanup_script_path"

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

	# prepare install directory
    mkdir -p "$INSTALL_DIR"

    # write cleanup script
    write_cleanup_script

    # install docker-ce package
    install_docker "$ENABLE_DOCKER_PACKAGE_MIRROR_FLAG"

    # install kubectl
    install_kubectl

    # log main function executed
    log_message "executed main function"
}

# =============================================================================
# Invoke main entry function.
# =============================================================================
log_message "Controller VM configuration starting."

main

log_message "Controller VM configuration completed."