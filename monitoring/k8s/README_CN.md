# 在Azure平台上监控部署在Kubernetes集群中的微服务

<a href="https://portal.azure.cn/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdevops-sample-solution-for-azure-china%2Fmaster-dev%2Fmonitoring%2Fk8s%2Fdeployment%2Fcontroller_template.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdevops-sample-solution-for-azure-china%2Fmaster-dev%2Fmonitoring%2Fk8s%2Fdeployment%2Fcontroller_template.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

运行ARM模板会在中国区Azure中部署一个规模为Standard_A1的Linux Ubuntu 16.04的虚拟机作为跳板机。跳板机用来访问和管理用户提供的Kubernetes集群，安装监控使用的Helm Charts，并为Kubernetes集群中服务部署Nginx入口服务。

我们提供两种监控方案：
* Heapster + Influxdb + Grafana： 监控集群资源，例如虚拟机节点的CPU和内存，Pod的CPU和内存
* Beats + Logstash + Elasticsearch + Kibana (ELK)： 监控容器和应用，例如容器中的日志和服务的心跳

## 前期准备
* 中国区Azure订阅
* 准备监控的Kubernetes集群 

## A. 部署跳板机，安装监控环境
1. 点击上面的"Deply to Azure"（部署到Azure）链接
2. 输入以下参数

| 参数                       | 描述                                                               | 默认值   |
|---------------------------------|--------------------------------------------------------------------------|-----------------|
| vmDnsName                       | 跳板机DNS名称                                            |                 |
| vmAdminUsername                 | 跳板机管理员用户名                            | azureuser       |
| vmAdminPassword                 | 跳板机管理员密码                            |                 |
| vmUbuntuOSVersion               | 跳板机Ubuntu版本                                 | 16.04.0-LTS     |
| vmSize                          | 跳板机规模                            | Standard_A1     |
| k8sMasterNodeHostname           | Kubernetes集群Master节点主机名                                  |                 |
| k8sMasterNodeUsername           | Kubernetes集群Master节点用户名                                  |                 |
| k8sMasterNodeIdentityFileBase64 | Kubernetes集群Master节点私钥，Base64编码    |                 |
| monitorClusterNamespace         | Kubernetes集群中监控命名空间                               |                 |
| azureCloudEnvironment           | Azure环境，'AzureCloud'（国际版）或'AzureChinaCloud'（中国版）                | AzureChinaCloud |
| enableElkStack                  | 是否部署ELK方案                       | enabled         |
| enableHigStack                  | 是否部署Heapster-InfluxDB-Grafana方案 | enabled         |


## B. 登陆到跳板机
1. 当部署执行成功后，得到跳板机的公有IP地址和DNS
2. 用部署时提供的管理员用户名和密码通过SSH登陆到跳板机
3. 执行下面kubectl命令，确认跳板机成功访问Kubernetes集群
```
Kubectl cluster-info
```
4. 打开浏览器，访问http://< 跳板机公有IP或DNS >/ui, 输入部署时提供的管理员用户名和密码，确认成功访问Kubernetes UI

## C. 检查监控环境
1. 在kubernetes UI中，确认部署时提供的命名空间（Namespace）存在，选择该命名空间
2. 在服务（Service）页面，确认Grafana和Kibana两个服务正常运行，并且有各自的公有IP地址
3. 通过Grafana的公有IP地址访问Granfa网站，确认仪表板（Dashboard）列表中包含Cluster和Node两个仪表盘，并且有实时数据显示
4. 通过Kibana的公有IP地址访问Kibana网站，添加下面两个Index Pattern
   * filebeat-*
   * heartbeat-* （默认已添加）
   在Discover页面，确认上面两个Index Pattern的数据正常收集。在Dashboard页面，确认包含Heartbeat HTTP monitoring仪表板

## D. 自定义监控数据
ELK方案中使用[Beats](https://www.elastic.co/products/beats)收集监控数据。在项目中我们使用[Filebeat](https://www.elastic.co/products/beats/filebeat)收集容器日志，[Heartbeat](https://www.elastic.co/products/beats/heartbeat)收集服务的心跳数据。

用户可以根据需求对Beats进行配置（所有配置细节请参考Beats官方文档）。以Heartbeat为例，配置Heatbeat来监控Kubernetes集群中用户自己的服务：
1. 通过SSH登陆到跳板机，切换到root (sudo -i)
2. 在跳板机/tmp/install/msref目录下，包含了下载的当前repo的全部文件
3. 在monitoring/k8s/helm-charts/configs/heartbeat-config目录下，编辑 heartbeat.yml文件 （参考 [Heartbeat Configuration Options](https://www.elastic.co/guide/en/beats/heartbeat/current/heartbeat-configuration-details.html)）
4. 返回monitoring/k8s/helm-charts目录，执行以下命令更新heartbeat的部署
```
yes | cp -rf configs/heartbeat-config/heartbeat.yml heartbeat/config
helm upgrade -f configs/heartbeat.yaml heartbeat heartbeat/
```


## GitHub参考项目

### [elk-acs-kubernetes](https://github.com/Microsoft/elk-acs-kubernetes) (MIT License)

项目包含了在国际版Azure中部署ELK监控方案，来监控通过Azure Container Service部署的Kubernetes集群。

### [charts](https://github.com/kubernetes/charts) (Apach-2.0 License)

项目包含了官方Kubernetes Helm Charts。关于如何安装和使用Helm请参考官方repo中的README.md文件。