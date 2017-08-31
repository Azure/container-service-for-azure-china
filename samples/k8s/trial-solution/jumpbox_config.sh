#!/usr/bin/env bash
#
# Configure jumpbox VM environments.
#

set -e

# =============================================================================
# constants
# =============================================================================

# script info
readonly CONFIG_SCRIPT_VERSION="1.0.0.12"

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
UTILITIES_PATH=${CURRENT_PATH}/jumpbox_utilities.sh

# azure environments
readonly AZURE_CLOUD="AzureCloud"
readonly AZURE_CHINA_CLOUD="AzureChinaCloud"

# command line arguments

RESOURCE_GROUP_NAME=""
RESOURCE_GROUP_LOCATION=""
SERVICE_PRINCIPAL_TENANT_ID=""
SERVICE_PRINCIPAL_CLIENT_ID=""
SERVICE_PRINCIPAL_SECRET=""
CLOUD_ENVIRONMENT_NAME="${AZURE_CLOUD}"
K8S_MASTER_DNS_NAME=""
K8S_LINUX_ADMIN_USER_NAME=""
K8S_LINUX_SSH_PUBLIC_KEY=""
K8S_LINUX_SSH_PRIVATE_KEY_BASE64=""
K8S_UI_ADMIN_USER_NAME=""
K8S_UI_ADMIN_PASSWORD=""

# =============================================================================
# functions
# =============================================================================

function parse_args() {
    while [ "$#" -gt 0 ]
    do
        arg_value="$2"
        shift_once=0

        if [[ "${arg_value}" =~ "--" ]] ; then
            arg_value=""
            shift_once=1
        fi

        log_message_direct "Option '$1' set with value: ${arg_value}"

        case "$1" in
            --help|-h)
                exit ${ERROR_INVALID_ARGS}
                ;;
            --rg-name)
                RESOURCE_GROUP_NAME="${arg_value}"
                ;;
            --rg-location)
                RESOURCE_GROUP_LOCATION="${arg_value}"
                ;;
            --sp-tenant-id)
                SERVICE_PRINCIPAL_TENANT_ID="${arg_value}"
                ;;
            --sp-client-id)
                SERVICE_PRINCIPAL_CLIENT_ID="${arg_value}"
                ;;
            --sp-client-secret)
                SERVICE_PRINCIPAL_SECRET="${arg_value}"
                ;;
            --cloud-env-name)
                if [ "${arg_value}" = "${AZURE_CLOUD}" ] || \
                   [ "${arg_value}" = "${AZURE_CHINA_CLOUD}" ] ; then
                    CLOUD_ENVIRONMENT_NAME="${arg_value}"
                else
                    log_message_direct "ERROR: invalid argument value: ${arg_value}"
                    exit ${ERROR_INVALID_ARGS}
                fi
                ;;
            --k8s-master-dns-name)
                K8S_MASTER_DNS_NAME="${arg_value}"
                ;;
            --k8s-linux-admin-user-name)
                K8S_LINUX_ADMIN_USER_NAME="${arg_value}"
                ;;
            --k8s-linux-ssh-pub-key)
                K8S_LINUX_SSH_PUBLIC_KEY="${arg_value}"
                ;;
            --k8s-linux-ssh-private-key-base64)
                K8S_LINUX_SSH_PRIVATE_KEY_BASE64="${arg_value}"
                ;;
            --k8s-ui-admin-user-name)
                K8S_UI_ADMIN_USER_NAME="${arg_value}"
                ;;
            --k8s-ui-admin-password)
                K8S_UI_ADMIN_PASSWORD="${arg_value}"
                ;;
            *) # unknown option
                log_message_direct "ERROR: Option '${BOLD}$1${NORM} ${arg_value}' not allowed."
                exit ${ERROR_INVALID_ARGS}
                ;;
        esac

        shift

        if [ $shift_once -eq 0 ] ; then
            shift
        fi

    done
}

function generate_k8s_arm_template() {
    local temp_file="${TMP_DIR}/kubernetes.json"

    # TODO: change to github raw link after public this repo
    curl -L "https://ccgmsref.blob.core.windows.net/scripts/k8s_trial/kubernetes.json" -o ${temp_file}

    sed -i "s/{K8S_MASTER_DNS_NAME}/${K8S_MASTER_DNS_NAME}/" ${temp_file}
    sed -i "s/{K8S_LINUX_ADMIN_USER_NAME}/${K8S_LINUX_ADMIN_USER_NAME}/" ${temp_file}
    sed -i "s~{K8S_LINUX_SSH_PUBLIC_KEY}~${K8S_LINUX_SSH_PUBLIC_KEY}~" ${temp_file}
    sed -i "s/{SERVICE_PRINCIPAL_CLIENT_ID}/${SERVICE_PRINCIPAL_CLIENT_ID}/" ${temp_file}
    sed -i "s/{SERVICE_PRINCIPAL_SECRET}/${SERVICE_PRINCIPAL_SECRET}/" ${temp_file}

    local output_dir="${TMP_DIR}/k8s_arm"

    mkdir -p ${output_dir}

    acs-engine generate ${temp_file} --output-directory ${output_dir}
}

# workaround method to replace Mooncake settings
function modify_k8s_arm_template_for_mooncake() {
    local arm_params_file=$"${TMP_DIR}/k8s_arm/azuredeploy.parameters.json"
    local arm_params_mc_file=$"${TMP_DIR}/k8s_arm/azuredeploy.parameters_mc.json"

    cat ${arm_params_file} | tr '\n' '\r' | sed "s/location\":\s{\r\s\+\"value\":\s\"/&${RESOURCE_GROUP_LOCATION}/" | tr '\r' '\n' > ${arm_params_mc_file}

    sed -i "s/AzurePublicCloud/AzureChinaCloud/" ${arm_params_mc_file}
    sed -i "s~https://aptdocker.azureedge.net/repo~https://mirror.azure.cn/docker-engine/apt/repo~" ${arm_params_mc_file}
    sed -i "s~gcrio.azureedge.net~crproxy.trafficmanager.net:6000~" ${arm_params_mc_file}

    mv ${arm_params_mc_file} ${arm_params_file}
}

function deploy_k8s_cluster() {
    az cloud set --name ${CLOUD_ENVIRONMENT_NAME}
    az login --service-principal --tenant ${SERVICE_PRINCIPAL_TENANT_ID} -u ${SERVICE_PRINCIPAL_CLIENT_ID} -p ${SERVICE_PRINCIPAL_SECRET}

    if [ "$(az group exists --name ${RESOURCE_GROUP_NAME})" = "false" ] ; then
        az group create --name ${RESOURCE_GROUP_NAME} --location ${RESOURCE_GROUP_LOCATION}
    fi

    local template_file=$"${TMP_DIR}/k8s_arm/azuredeploy.json"
    local params_file=$"${TMP_DIR}/k8s_arm/azuredeploy.parameters.json"

    az group deployment create --name "k8sdeploy" --resource-group ${RESOURCE_GROUP_NAME} --template-file ${template_file} --parameters ${params_file}

    mkdir -p ${KUBE_CONFIG_DIR}

    cp $"${TMP_DIR}/k8s_arm/kubeconfig/kubeconfig.${RESOURCE_GROUP_LOCATION}.json" ${KUBECONFIG}

    kubectl version
}

function configure_nginx_k8s_proxy() {
    echo "${K8S_UI_ADMIN_PASSWORD}" | htpasswd -c -i /etc/nginx/.htpasswd "${K8S_UI_ADMIN_USER_NAME}"

    local nginx_config="server {
        listen 80 default_server;
        listen [::]:80 default_server;

        server_name _;

        location / {
                proxy_pass http://localhost:8080;
                auth_basic \"Restrict Access\";
                auth_basic_user_file /etc/nginx/.htpasswd;
        }
}"

    echo -e "${nginx_config}" > "/etc/nginx/sites-available/default"

    nohup kubectl proxy --port=8080 > "/var/log/kubeproxy.log" 2>&1 &

    systemctl reload nginx

    # test nginx
    sleep 10
    curl http://localhost/ -u "${K8S_UI_ADMIN_USER_NAME}:${K8S_UI_ADMIN_PASSWORD}"
}

function main() {
    install_tools

    generate_k8s_arm_template

    if [ "${CLOUD_ENVIRONMENT_NAME}" = "${AZURE_CHINA_CLOUD}" ] ; then
        modify_k8s_arm_template_for_mooncake
    fi

    deploy_k8s_cluster
}

# =============================================================================
# Start Execution
# =============================================================================

if [ ! -e ${UTILITIES_PATH} ] ;  then
    echo :"Utilities not present at ${UTILITIES_PATH}"
    exit 3 # ERROR_MISSING_UTILITIES
fi

source ${UTILITIES_PATH}

log_message_direct "=========================================================="
log_message_direct "Script name: $0"
log_message_direct "Config Script version: $CONFIG_SCRIPT_VERSION"
log_message_direct "Utilities Script version: $UTILITIES_SCRIPT_VERSION"
log_message_direct "Configuring jumpbox VM with args: $*"

# prepare temporary directory
mkdir -p "$TMP_DIR"

log_message_direct "Temporary directory: $TMP_DIR"

# parse command line arguments
parse_args "$@"

# Invoke main entry function.
main 2>&1 | tee -a $LOG_FILE

log_message_direct "Configured jumpbox VM configuration successfully."