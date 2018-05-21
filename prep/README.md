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

# 1809 Container Host
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

docker load ...

### Build Windows Server 1803 Host VMs in Azure

Build a Windows Server 1803 Host VM (with container support) for each attendee.

