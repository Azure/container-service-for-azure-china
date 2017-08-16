# manually config controller machine

# instructions
# 1. [required] set K8S_MASTER_NODE_HOSTNAME with kubernetes cluster master node hostname
# 2. [required] set K8S_MASTER_NODE_USERNAME with kubernetes cluster master node username
# 3. [required] set K8S_MASTER_NODE_IDENTITY_FILE_PATH with kubernetes cluster master node identity file path
# 4. [required] set K8S_UI_ADMIN_USERNAME with admin username to access kubernetes ui
# 5. [required] set K8S_UI_ADMIN_PASSWORD with admin password to access kubernetes ui
# 6. [optional] set MONITOR_CLUSTER_NS, ENABLE_ELK_STACK, ENABLE_HIG_STACK on demand
# 7. save changes and execute this script.

# constants
CONFIG_SCRIPT_PATH="./config.sh"
K8S_MASTER_NODE_HOSTNAME="<k8s-cluster-master>.chinaeast.cloudapp.azure.cn"
K8S_MASTER_NODE_USERNAME="<username>"
K8S_MASTER_NODE_IDENTITY_FILE_PATH="<id-rsa-path>"
K8S_UI_ADMIN_USERNAME="<admin-username>"
K8S_UI_ADMIN_PASSWORD="<admin-password>"
AZURE_CLOUD_ENV="AzureChinaCloud"
MONITOR_CLUSTER_NS="monitor-cluster-ns"
ENABLE_ELK_STACK="enabled"
ENABLE_HIG_STACK="enabled"

bash "$CONFIG_SCRIPT_PATH" \
    --azure-cloud-env="$AZURE_CLOUD_ENV" \
    --k8s-master-node-hostname="$K8S_MASTER_NODE_HOSTNAME" \
    --k8s-master-node-username="$K8S_MASTER_NODE_USERNAME" \
    --k8s-master-node-id-file-base64="$(base64 $K8S_MASTER_NODE_IDENTITY_FILE_PATH)" \
    --k8s-ui-admin-username="$K8S_UI_ADMIN_USERNAME" \
    --k8s-ui-admin-password="$K8S_UI_ADMIN_PASSWORD" \
    --monitor-cluster-ns="$MONITOR_CLUSTER_NS" \
    --enable-elk-stack="$ENABLE_ELK_STACK" \
    --enable-hig-stack="$ENABLE_HIG_STACK"