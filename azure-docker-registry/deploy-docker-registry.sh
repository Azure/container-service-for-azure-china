#!/bin/bash

usage(){
  echo "Invalid option: -$OPTARG"
  echo "Usage: deploy-docker-registry -n [Resource group name]"
  echo "                              -l [Resource group location]"
  exit 1
}

while getopts ":n:l:" opt; do
  case $opt in
    n)GROUP_NAME=$OPTARG;;
    l)LOCATION=$OPTARG;;
    *)usage;;
  esac
done

if [ -z $GROUP_NAME ] || [ -z $LOCATION ]; then
  usage
  exit 1
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

sed -i 's/\r$//' cloud-config.yml
sed -i 's/\\/\\\\/g' cloud-config.yml
sed -i ':a;N;$!ba;s/\n/\\n/g' cloud-config.yml
sed -i 's/\\n/\\\\n/g' cloud-config.yml
sed -i 's/"/\\"/g' cloud-config.yml
sed -i "s/<<<\([^>]*\)>>>/',\1,'/g" cloud-config.yml

INITCONTENT=$(cat cloud-config.yml)
echo "[base64(concat('$INITCONTENT'))]" > updatepattern.txt
sed -i "s/<<<[^>]*>>>/$(sed 's:/:\\/:g; s:&:\\&:g; s:\\\":\\\\\":g;' updatepattern.txt)/g" $TEMPLATE

azure config mode arm
azure group create -n "$GROUP_NAME" -l "$LOCATION" -f $TEMPLATE -e $PARAMETERS  -v

rm $TEMPLATE
rm cloud-config.yml
rm updatepattern.txt