# 下载并解压acs-engine
# 准备一个[SSH公钥私钥对](https://github.com/Azure/acs-engine/blob/master/docs/ssh.md#ssh-key-generation)
# [安装azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
# 创建Service Principle
# 编辑[kubernetes.json](https://raw.githubusercontent.com/Azure/acs-engine/master/examples/kubernetes.json),将其需要的参数配置好
  * dnsPrefix：唯一的关键字
  * keyData：SSH公钥
  * clientId: 对应于Service Principle中的appId
  * secret：对应于Service Principle中的password
  * 增加"location": "chinaeast"
# 生成ARM模板
  
# 使用ARM模板部署K8S容器集群


