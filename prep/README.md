# Workshop Prep

## Coach

### Build Windows Server Container Hosts in Azure

Build a Windows Server 1709 and 1803 Container host in Azure

```bash
$ az vm create -n win1709-01 -g ContainerCamp-VMs --image "MicrosoftWindowsServer:WindowsServerSemiAnnual:Datacenter-Core-1709-with-Containers-smalldisk:1709.0.20180412" --size Standard_D4s_v3 --os-disk-size-gb 2048 --admin-username coach --admin-password <password>

$ az vm create -n win1803-01 -g ContainerCamp-VMs --image "MicrosoftWindowsServer:WindowsServerSemiAnnual:Datacenter-Core-1803-with-Containers-smalldisk:1803.0.20180504" --size Standard_D4s_v3 --os-disk-size-gb 2048 --admin-username coach --admin-password  <password>

```

Ensure that the following images have been pulled onto these machines:

```powershell

# 1709 Container Host
PS> docker pull microsoft/windowsservercore:1709
PS> docker pull microsoft/nanoserver:1709
PS> docker pull microsoft/windowsservercore:1803

# 1803 Container Host
PS> docker pull microsoft/dotnet-framework-samples:dotnetapp-windowsservercore-1709
PS> docker pull microsoft/dotnet-framework-samples:dotnetapp-windowsservercore-1803
PS> docker pull microsoft/windowsservercore:1709
PS> docker pull microsoft/nanoserver:1709
PS> docker pull microsoft/windowsservercore:1803
PS> docker pull microsoft/windowsservercore:1803_KB4103721
PS> docker pull microsoft/nanoserver:1803
PS> docker pull microsoft/nanoserver:1803_KB4103721
PS> docker pull microsoft/dotnet-framework:4.7.2-sdk-windowsservercore-1803
PS> docker pull microsoft/aspnet:4.7.2-windowsservercore-1803
```


### Build Windows Server 1803 Host VM in Azure

## Attendees

### Have 1709 and 1803 Container Image copies

Copy the following zipped images:

```
microsoft-aspnet-4.7.2-windowsservercore-1803.zip
microsoft-dotnet-framework-4.7.2-windowsservercore-1803.zip
microsoft-iis-windowsservercore-1803-image.zip
microsoft-windowsservercore_1709-image.zip
microsoft-windowsservercore_1803-image.zip
microsoft-windowsservercore_ltsc2016-image.zip
```

Unzip them:

```
microsoft-aspnet-4.7.2-windowsservercore-1803.tar
microsoft-dotnet-framework-4.7.2-windowsservercore-1803.tar
microsoft-iis-windowsservercore-1803-image.tar
microsoft-windowsservercore_1709-image.tar
microsoft-windowsservercore_1803-image.tar
microsoft-windowsservercore_ltsc2016-image.tar
```

Then load them into docker as follows:

```
docker load -i microsoft-aspnet-4.7.2-windowsservercore-1803.tar
docker load -i microsoft-dotnet-framework-4.7.2-windowsservercore-1803.tar
docker load -i microsoft-iis-windowsservercore-1803-image.tar
docker load -i microsoft-windowsservercore_1709-image.tar
docker load -i microsoft-windowsservercore_1803-image.tar
docker load -i microsoft-windowsservercore_ltsc2016-image.tar
```

### Build Windows Server 1803 Host VMs in Azure

Build a Windows Server 1803 Host VM (with container support) for each attendee.

