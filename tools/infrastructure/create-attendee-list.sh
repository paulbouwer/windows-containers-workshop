#/bin/ash

count=$1
offset=21
resourceGroup=ContainerCamp-VMs

if [ -f ./attendees-detail.txt ]; then
  rm ./attendees-detail.txt
fi

if [ -f ./attendees-az-vm-create.sh ]; then
  rm ./attendees-az-vm-create.sh
fi
echo -e "#!/bin/bash\n" > ./attendees-az-vm-create.sh

if [ -f ./attendees-az-vm-publicipaddress.sh ]; then
  rm ./attendees-az-vm-publicipaddress.sh
fi
echo -e "#!/bin/bash\n" > ./attendees-az-vm-publicipaddress.sh

if [ -f ./attendees-az-vm-nsg.sh ]; then
  rm ./attendees-az-vm-nsg.sh
fi
echo -e "#!/bin/bash\n" > ./attendees-az-vm-nsg.sh

for i in `seq $offset $(($offset + $count))`; do
    code=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
    password="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)$(cat /dev/urandom | tr -dc '0-9' | fold -w 2 | head -n 1)"

    printf "%s|workshopuser%02d|%s|win1803-%02d\n" $code $i $password $i >> ./attendees-detail.txt

    printf "az vm create -n win1803-%02d -g %s --image 'MicrosoftWindowsServer:WindowsServerSemiAnnual:Datacenter-Core-1803-with-Containers-smalldisk:1803.0.20180504' --size Standard_D4s_v3 --os-disk-size-gb 2048 --admin-username workshopuser%02d --admin-password %s --no-wait\n" $i $resourceGroup $i $password >> ./attendees-az-vm-create.sh

    printf "publicIpAddress=\$(az vm show -g %s -n win1803-%02d -d --query 'publicIps' -o tsv)\nisRunning=\$(az vm show -g %s -n win1803-%02d -d --query "powerState" -o tsv)\necho \"win1803-%02d|\$publicIpAddress|\$isRunning\"\n" $resourceGroup $i $resourceGroup $i $i >> ./attendees-az-vm-publicipaddress.sh

    printf "az network nsg rule create -g %s --nsg-name win1803-%02dNSG -n TCP_8080 --priority 110 --access Allow --protocol Tcp --direction Inbound --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 8080\n" $resourceGroup $i >> ./attendees-az-vm-nsg.sh
    printf "az network nsg rule create -g %s --nsg-name win1803-%02dNSG -n TCP_8081 --priority 120 --access Allow --protocol Tcp --direction Inbound --source-address-prefixes '*' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 8081\n" $resourceGroup $i >> ./attendees-az-vm-nsg.sh

done
