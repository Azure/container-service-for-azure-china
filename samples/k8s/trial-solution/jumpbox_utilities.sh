#!/usr/bin/env bash
#
# Utilities function.
#

# =============================================================================
# Error Codes
# =============================================================================

# general error
readonly ERROR_UNKNOWN_ERROR=1
readonly ERROR_INVALID_ARGS=2
readonly ERROR_MISSING_UTILITIES=3

# dependencies error
readonly ERROR_DOCKER_INSTALL_FAILED=1001
readonly ERROR_KUBECTL_INSTALL_FAILED=1002
readonly ERROR_ACS_ENGINE_INSTALL_FAILED=1003

# =============================================================================
# constants
# =============================================================================

# script info
readonly UTILITIES_SCRIPT_VERSION="1.0.0.12"

# temporary directory
readonly TMP_DIR="/tmp/jumpbox"

# log file
readonly LOG_FILE="/var/log/jumpbox.log"

# docker install path
readonly DOCKER_INSTALL_PATH=/usr/bin/docker

# kubectl install path
readonly KUBECTL_INSTALL_PATH=/usr/local/bin/kubectl

# acs-engine install path
readonly ACS_ENGINE_INSTALL_PATH=/usr/local/bin/acs-engine

# kubernetes environments

KUBE_CONFIG_DIR="/root/.kube"
export KUBECONFIG="${KUBE_CONFIG_DIR}/config"

# =============================================================================
# functions
# =============================================================================

function log_message() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") $1"
}

function log_message_direct() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") $1" | tee -a ${LOG_FILE}
}

function install_docker() {
    if type docker > /dev/null 2>&1 ; then 
        log_message "docker already installed."
    else
        if [ ${CLOUD_ENVIRONMENT_NAME} = ${AZURE_CHINA_CLOUD} ] ; then
            curl -fsSL "https://mirror.azure.cn/docker-engine/apt/gpg" | sudo apt-key add -
            add-apt-repository "deb [arch=amd64] https://mirror.azure.cn/docker-engine/apt/repo ubuntu-xenial main"
        else
            curl -fsSL "https://aptdocker.azureedge.net/repo" | sudo apt-key add -
            add-apt-repository "deb [arch=amd64] https://aptdocker.azureedge.net/repo ubuntu-xenial main"
        fi

        apt-get update --fix-missing
        apt-cache policy docker-engine
        apt-get install -y docker-engine

        # test install
        docker --version
    fi
}

function install_kubectl() {
    if type kubectl > /dev/null 2>&1 ; then 
        log_message "kubectl already installed."
    else
        local tmp_file="${TMP_DIR}/kubectl"

        if [ ${CLOUD_ENVIRONMENT_NAME} = ${AZURE_CHINA_CLOUD} ] ; then
            curl -L "https://ccgmsref.blob.core.windows.net/mirror/kubectl" -o "${tmp_file}"
        else
            curl -L "https://storage.googleapis.com/kubernetes-release/release/v1.6.6/bin/linux/amd64/kubectl" -o "${tmp_file}"
        fi

        chmod +x "${tmp_file}"
        mv "${tmp_file}" "${KUBECTL_INSTALL_PATH}"

        # test install
        kubectl version --client
    fi
}

function install_acs_engine() {
    if type acs-engine > /dev/null 2>&1 ; then 
        log_message "acs-engine already installed."
    else
        local tmp_file="${TMP_DIR}/acs-engine"
        curl -L "https://ccgmsref.blob.core.windows.net/release/acs-engine" -o "${tmp_file}"
        chmod +x "${tmp_file}"
        mv "${tmp_file}" "${ACS_ENGINE_INSTALL_PATH}"

        # test install
        acs-engine
    fi
}

function install_azure_cli_v2() {
    if type az > /dev/null 2>&1 ; then 
        log_message "azure cli 2.0 already installed."
    else
        echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/azure-cli/ wheezy main" | tee /etc/apt/sources.list.d/azure-cli.list
        apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
        apt-get install -y apt-transport-https
        apt-get update 
        apt-get install -y azure-cli

        # test install
        az
    fi
}

function install_nginx() {
    if type nginx > /dev/null 2>&1 ; then 
        log_message "nginx already installed."
    else
        apt-get install nginx apache2-utils -y

        # test install
        nginx -v
    fi
}

function install_tools() {
    install_docker

    install_kubectl

    install_acs_engine

    install_azure_cli_v2

    install_nginx
}
