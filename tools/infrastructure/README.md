Generate workshop users and password
Leverage to generate VMs using az vm
Query created VMs using az vm and get ip address, update list
print out list for attendees ..

```bash
# Loop with incrementing counter on -n, --admin-username fields and random value for --admin-password field
az vm create -n win1803-01 -g ContainerCamp-VMs --image "MicrosoftWindowsServer:WindowsServerSemiAnnual:Datacenter-Core-1803-with-Containers-smalldisk:1803.0.20180504" --size Standard_D4s_v3 --os-disk-size-gb 2048 --admin-username workshopuser01 --admin-password <password>
```


```bash

$ password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

$ resourceGroup=CC2018AU-VM
$ vmName=win1803-01

# check if VM is running yet
$ isRunning=$(az vm show -g $resourceGroup -n $vmName -d --query "powerState" -o tsv)
$ if [[ $isRunning = "VM running" ]]; then echo "yes"; fi

# if it is, get the public ip address
$ publicIpAddress=$(az vm show -g $resourceGroup -n $vmName -d --query "publicIps" -o tsv)

# if it is, set up the NSG to allow RDP, 8080 and 8081
$ nicId=$(az vm show -g $resourceGroup -n $vmName --query "networkProfile.networkInterfaces[0].id" -o tsv)
$ nsgId=$(az resource link show --link-id $nicId --query "properties.additionalProperties.networkSecurityGroup.id" -o tsv)
$ nsgName=$(az resource link show --link-id $nsgId --query "name" -o tsv)
$ az network nsg rule create -g $resourceGroup --nsg-name $nsgName \
   -n RDP --priority 100 \
   --access Allow --protocol Tcp --direction Inbound \
   --source-address-prefixes '*' --source-port-ranges '*' \
   --destination-address-prefixes '*' --destination-port-ranges 3389

$ az network nsg rule create -g $resourceGroup --nsg-name $nsgName \
   -n TCP_8080 --priority 110 \
   --access Allow --protocol Tcp --direction Inbound \
   --source-address-prefixes '*' --source-port-ranges '*' \
   --destination-address-prefixes '*' --destination-port-ranges 8080

$ az network nsg rule create -g $resourceGroup --nsg-name $nsgName \
   -n TCP_8081 --priority 120 \
   --access Allow --protocol Tcp --direction Inbound \
   --source-address-prefixes '*' --source-port-ranges '*' \
   --destination-address-prefixes '*' --destination-port-ranges 8081
```

