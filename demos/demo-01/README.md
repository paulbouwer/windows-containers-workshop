# Demo 1 - Windows Containers - Basics

## Windows Container Versions

Browse to [microsoft/windowsservercore](https://hub.docker.com/r/microsoft/windowsservercore/tags/) tags on Docker Hub and show the various labels. Do the same for [microsoft/nanoserver](https://hub.docker.com/r/microsoft/nanoserver/tags/) tags.

Show the labels in a filtered manner:

```bash
# Long Term Servicing Channel (LTSC)
$ docker run --rm docker-registry-tags:1.0 microsoft/windowsservercore ltsc
$ docker run --rm docker-registry-tags:1.0 microsoft/windowsservercore 10.0.14393

# Semi-Annual Channel (SAC) - 1709
$ docker run --rm docker-registry-tags:1.0 microsoft/windowsservercore 1709

# Semi-Annual Channel (SAC) - 1803
$ docker run --rm docker-registry-tags:1.0 microsoft/windowsservercore 1803
```

## Windows Container Version Compatibility

### Windows Server version 1709 Host

Attempt to run a Windows Server Core 1803 container

```bash
$ docker run --rm microsoft/windowsservercore:1803 powershell
```

You should see something like the following error message:

```bash
# The operating system of the container does not match the operating system of the host
docker: Error response from daemon: container bd9e3b5415a4774cb268987916639c6335880e354c6c2a5a8583993038eb4c6a encountered an error during CreateContainer: failure in a Windows system call: The operating system of the container does not match the operating system of the host. (0xc0370101) extra info: {"SystemType":"Container","Name":"bd9e3b5415a4774cb268987916639c6335880e354c6c2a5a8583993038eb4c6a","Owner":"docker","IsDummy":false,"VolumePath":"\\\\?\\Volume{817bdaf8-b5ef-4b70-b504-468470b5728a}","IgnoreFlushesDuringBoot":true,"LayerFolderPath":"C:\\ProgramData\\docker\\windowsfilter\\bd9e3b5415a4774cb268987916639c6335880e354c6c2a5a8583993038eb4c6a","Layers":[{"ID":"d54387b5-f568-5cd1-aac0-4ad1b196cea6","Path":"C:\\ProgramData\\docker\\windowsfilter\\1c2240b93fb931b077034e69a1d7e283096e29e5fced79bebcf55c839b141693"},{"ID":"458fd2e2-c938-5003-aca1-781fb436ac82","Path":"C:\\ProgramData\\docker\\windowsfilter\\93d550dd79e79f050d7631152477dc435540306289effead715a12abc921bc3a"}],"HostName":"bd9e3b5415a4","MappedDirectories":[],"HvPartition":false,"EndpointList":["cebb0083-951e-4b52-a236-8eac028dead8"],"Servicing":false,"AllowUnqualifiedDNSQuery":true}.
```

Attempt to run a Windows Server Core 1803 container with Hyper-V isolation

```bash
$ docker run --isolation=hyperv --rm microsoft/windowsservercore:1803 powershell
```

You should see something like the following error message:

```bash
# The JSON document is invalid.
docker: Error response from daemon: container 37dc1c84a111354d19e2555ad38ee13b3c89c56e9cca01671c1cf94a85299b55 encountered an error during Start: failure in a Windows system call: The JSON document is invalid. (0xc037010d).
```

> Windows Server Containers are blocked from starting when the build number between the container host and the container image are different.

### Windows Server version 1803 Host

The following will all work since the container host and container image share the same build number (kernel version).

```powershell
PS> docker run --rm microsoft/windowsservercore:1803 cmd /c ver
PS> docker run --rm --isolation=hyperv microsoft/windowsservercore:1803 cmd /c ver
PS> docker run --rm microsoft/windowsservercore:1803 powershell [environment]::OSVersion.Version
```

When running 1709 on 1803 as a Windows Container you will get an error since the container host and container image have different build numbers.

```powershell
PS> docker run --rm microsoft/windowsservercore:1709 cmd /c ver

# The operating system of the container does not match the operating system of the host.
C:\Program Files\Docker\docker.exe: Error response from daemon: container e5785d1cc3d5e870eae9a267e791fb2a80d76b400e8aa84af47309e0e8e5d375 encountered an error during CreateContainer: failure in a Windows system call: The operating system of the container does not match the operating system of the host. (0xc0370101) extra info: {"SystemType":"Container","Name":"e5785d1cc3d5e870eae9a267e791fb2a80d76b400e8aa84af47309e0e8e5d375","Owner":"docker","IsDummy":false,"VolumePath":"\\\\?\\Volume{72b01d78-b4c1-4651-9754-4cd6ebbac792}","IgnoreFlushesDuringBoot":true,"LayerFolderPath":"C:\\ProgramData\\docker\\windowsfilter\\e5785d1cc3d5e870eae9a267e791fb2a80d76b400e8aa84af47309e0e8e5d375","Layers":[{"ID":"fd6a7029-5525-5d07-9801-63b5662892b7","Path":"C:\\ProgramData\\docker\\windowsfilter\\3bf978d8b1a2dfd1877075059d0adf53744354338446933787967e6eb0bec587"},{"ID":"809952c3-4053-5f5d-8db1-0f7a9681f46f","Path":"C:\\ProgramData\\docker\\windowsfilter\\f4f76e88a7ccd696f16a9497ae8d774cdc6e46194a3c8498013f1f7520048d98"}],"HostName":"e5785d1cc3d5","MappedDirectories":[],"HvPartition":false,"EndpointList":["ebdb2a42-c170-45b4-906d-e92f41f34537"],"Servicing":false,"AllowUnqualifiedDNSQuery":true}.
```

You will have to run the 1709 container image with Hyper-V isolation.

```powershell
PS> docker run --rm --isolation=hyperv microsoft/windowsservercore:1709 cmd /c ver
```

