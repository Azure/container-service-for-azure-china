#!/usr/bin/env bash

set -e

RESOURCE_LOCATION=$1
ADMIN_USERNAME=$2
ADMIN_PASSWORD=$3
MASTER_DNS=$4
MASTER_USERNAME=$5
BASED_PRIVATE_KEY=$6

export STORAGE_ACCOUNT=$7
export STORAGE_LOCATION=${RESOURCE_LOCATION}

PRIVATE_KEY='private_key'

MASTER_URL=${MASTER_DNS}

export KUBECONFIG=/root/.kube/config

# prerequisite
curl -fsSL https://mirror.azure.cn/docker-engine/apt/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://mirror.azure.cn/docker-engine/apt/repo ubuntu-xenial main"
sudo apt-get update --fix-missing
apt-cache policy docker-engine
sudo apt-get install -y unzip docker-engine nginx apache2-utils

# install kubectl
cd /tmp
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# write private key
echo "${BASED_PRIVATE_KEY}" | base64 -d | tee ${PRIVATE_KEY}
chmod 400 ${PRIVATE_KEY}

mkdir -p /root/.kube
scp -o StrictHostKeyChecking=no -i ${PRIVATE_KEY} ${MASTER_USERNAME}@${MASTER_URL}:.kube/config ${KUBECONFIG}
kubectl get nodes

# install helm
curl -s https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
helm init

# !!temp workaround -- update tiller image pulling from mirror!!
kubectl --namespace=kube-system set image deployments/tiller-deploy tiller=mirror.azure.cn:5000/kubernetes-helm/tiller:v2.5.1

# download templates
REPO_URL='https://miaosrc.blob.core.windows.net/src/microservice-reference-architectures.zip'

curl -L ${REPO_URL} -o template.zip
unzip -o template.zip -d template

# expose kubectl proxy
cd template/microservice-reference-architectures/
echo ${ADMIN_PASSWORD} | htpasswd -c -i /etc/nginx/.htpasswd ${ADMIN_USERNAME}
cp monitoring/k8s/controller/nginx-config/nginx-site.conf /etc/nginx/sites-available/default
nohup kubectl proxy --port=8080 &
systemctl reload nginx

# helm install 
cd monitoring/k8s/controller
bash start-heapster-influxdb-grafana.sh
