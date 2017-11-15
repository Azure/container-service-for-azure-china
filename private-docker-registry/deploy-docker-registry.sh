#!/bin/bash

usage(){
  echo "Invalid option: -$OPTARG"
  echo "Usage: deploy-docker-registry -n [Resource group name]"
  echo "                              -l [Resource group location]"
  echo "                              -m [Azure mirror site]"
  exit 1
}

while getopts ":n:l:m:" opt; do
  case $opt in
    n)GROUP_NAME=$OPTARG;;
    l)LOCATION=$OPTARG;;
    m)MIRROR=$OPTARG;;
    *)usage;;
  esac
done

if [ -z $GROUP_NAME ] || [ -z $LOCATION ]; then
  usage
  exit 1
fi

if [ -z $MIRROR ] ; then
  MIRROR="mirror.azure.cn"
fi

ARMTEMPLATE="azuredeploy-template.json"
TEMPLATE="azuredeploy.json"
PARAMETERS="azuredeploy.parameters.json"
CLOUDINIT="cloud-config-template.yml"
CERTFILE="./certs/server.crt"
KEYFILE="./certs/server.key"

CERTFILECONTENT=`cat "$CERTFILE"|base64 -w 0`
KEYFILECONTENT=`cat "$KEYFILE"|base64 -w 0`

cp -f $ARMTEMPLATE $TEMPLATE
cp -f $CLOUDINIT cloud-config.yml
sed -i "s|{{{serverCertificate}}}|$CERTFILECONTENT|g; s|{{{serverKey}}}|$KEYFILECONTENT|g;" cloud-config.yml
sed -i "s|{{{azureMirror}}}|$MIRROR|g;" cloud-config.yml

sed -i 's/\r$//' cloud-config.yml
sed -i 's/\\/\\\\/g' cloud-config.yml
sed -i ':a;N;$!ba;s/\n/\\n/g' cloud-config.yml
sed -i 's/\\n/\\\\n/g' cloud-config.yml
sed -i 's/"/\\"/g' cloud-config.yml
sed -i "s/<<<\([^>]*\)>>>/',\1,'/g" cloud-config.yml

INITCONTENT=$(cat cloud-config.yml)
echo "[base64(concat('$INITCONTENT'))]" > updatepattern.txt
sed -i "s/<<<[^>]*>>>/$(sed 's:/:\\/:g; s:&:\\&:g; s:\\\":\\\\\":g;' updatepattern.txt)/g" $TEMPLATE

if type az >/dev/null 2>&1 ; then
  echo "azure cli 2.0 already installed"
  
  az group create --name "$GROUP_NAME" --location "$LOCATION"
  az group deployment create -g "$GROUP_NAME" --template-file $TEMPLATE --parameters $PARAMETERS
else
  echo "azure cli 2.0 not found, installing..."

  echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
  sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893
  sudo apt-get install -q -y apt-transport-https
  sudo apt-get update
  sudo apt-get install -q -y azure-cli

  echo "please az login first, then re-run this script"
fi

rm $TEMPLATE
rm cloud-config.yml
rm updatepattern.txt