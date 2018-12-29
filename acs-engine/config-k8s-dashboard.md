## Config kubernetes dashboard (only for testing purpose)
 - Login to master node via SSH
```
ssh -i <path_to_id_rsa> <adminUsername>@<master_node_fqdn>
```
 - Download config_k8s_ui_http.sh script
```
curl -LO https://raw.githubusercontent.com/Azure/devops-sample-solution-for-azure-china/master-dev/acs-engine/config_k8s_ui_http.sh
```
 - Run following command:
```
bash config_k8s_ui_http.sh -c <cloud_name> -g <rg_name> -t <tenant_id> -i <app_id> -s <app_secret> -u <user_name> -p <user_pass>
```
Usages: 
* -c [Cloud instance name, AzureCloud or AzureChinaCloud]"
* -g [Resource group]"
* -t [Service principal tenantId, e.g. 89e1b688-8d74-xxx-9680-54d0a43a4f0d ]"
* -i [Service principal app id]"
* -s [Service principal secret]"
* -u [Kubernetes dashboard user name, default value is 'admin']"
* -p [Kubernetes dashboard user password, default value is 'password']"

 - Access dashboard via following link:
```
http://<master_node_fqdn>/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
```

> You may hit access error when using kubernetes dashboard, run following command and refresh:
> ```
> kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
> ```
