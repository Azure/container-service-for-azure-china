#!/bin/bash

usage(){
  echo "Invalid option: -$OPTARG"
  echo "Usage: deploy-docker-registry -n [Resource group name]"
  echo "                              -l [Resource group location]"
  echo "                              -m [Azure mirror site]"
  echo "                              -i [id_rsa file for SSH to k8s nodes]"
  echo "                              -u [user name for SSH to k8s nodes]"
  exit 1
}

while getopts ":n:l:m:i:u:" opt; do
  case $opt in
    n)GROUP_NAME=$OPTARG;;
    l)LOCATION=$OPTARG;;
    m)MIRROR=$OPTARG;;
    i)ID_RSA_FILE=$OPTARG;;
    u)K8S_USER=$OPTARG;;
    *)usage;;
  esac
done

if [ -z $GROUP_NAME ] || [ -z $LOCATION ]; then
  usage
  exit 1
fi

if [ -z $MIRROR ] ; then
  $MIRROR="mirror.azure.cn"
fi

ARMTEMPLATE="azuredeploy-template.json"
TEMPLATE="azuredeploy.json"
PARAMETERS="azuredeploy.parameters.json"
CLOUDINIT="cloud-config-template.yml"
CERTFILE="./certs/server.crt"
KEYFILE="./certs/server.key"

CERTFILECONTENT=`cat "$CERTFILE"|base64 -w 0`
KEYFILECONTENT=`cat "$KEYFILE"|base64 -w 0`
K8S_ID_RSA_CONTENT=`cat "$ID_RSA_FILE|base64 -w 0"`

cp -f $ARMTEMPLATE $TEMPLATE
cp -f $CLOUDINIT cloud-config.yml
sed -i "s|{{{serverCertificate}}}|$CERTFILECONTENT|g; s|{{{serverKey}}}|$KEYFILECONTENT|g;" cloud-config.yml
sed -i "s|{{{azureMirror}}}|$MIRROR|g;" cloud-config.yml

sed -i "s|{{{K8S_ID_RSA_CONTENT}}}|$K8S_ID_RSA_CONTENT|g;" cloud-config.yml
sed -i "s|{{{K8S_USER}}}|$K8S_USER|g;" cloud-config.yml

sed -i 's/\r$//' cloud-config.yml
sed -i 's/\\/\\\\/g' cloud-config.yml
sed -i ':a;N;$!ba;s/\n/\\n/g' cloud-config.yml
sed -i 's/\\n/\\\\n/g' cloud-config.yml
sed -i 's/"/\\"/g' cloud-config.yml
sed -i "s/<<<\([^>]*\)>>>/',\1,'/g" cloud-config.yml

INITCONTENT=$(cat cloud-config.yml)
echo "[base64(concat('$INITCONTENT'))]" > updatepattern.txt
sed -i "s/<<<[^>]*>>>/$(sed 's:/:\\/:g; s:&:\\&:g; s:\\\":\\\\\":g;' updatepattern.txt)/g" $TEMPLATE

az group create --name "$GROUP_NAME" --location "$LOCATION"
az group deployment create -g "$GROUP_NAME" --template-file $TEMPLATE --parameters $PARAMETERS

rm $TEMPLATE
rm cloud-config.yml
rm updatepattern.txt