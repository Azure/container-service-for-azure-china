# 下载并解压acs-engine, 也可以下载源代码进行编译
https://github.com/Azure/acs-engine/releases/tag/v0.8.0
# 准备一个[SSH公钥私钥对](https://github.com/Azure/acs-engine/blob/master/docs/ssh.md#ssh-key-generation)
# [安装azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
# 创建Service Principle
# 编辑[kubernetes.json](https://raw.githubusercontent.com/Azure/acs-engine/master/examples/kubernetes.json),将其需要的参数配置好
* dnsPrefix：设置集群DNS名称前缀
* keyData：对应于SSH公钥
* clientId: 对应于Service Principle中的appId
* secret：对应于Service Principle中的password
* 在apiVersion: "vlabs"后面增加位置信息"location": "chinaeast",
# 生成ARM模板
运行`acs-engine generate kubernetes.json`命令生成ARM模板
# 使用ARM模板部署K8S容器集群
```
az cloud set -n AzureChinaCloud
az login
az group create -l chinaeast -n xxx
az group deployment create -g xxx --template-file azuredeploy.json --parameters azuredeploy.parameters.json
```
