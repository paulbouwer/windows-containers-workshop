# Lab 1 - Exploring Windows Containers

## Notes

In this workshop there are two environments that you can run this lab in.

### Windows 10 Host with Docker for Windows
---

Ensure you have switched to **Windows Containers**. You can do this by right-clicking on the Docker icon in the sytem tray and selecting the `Switch to Windows containers...` option.

Windows Containers will only run under Hyper-V isolation on a Windows 10 Host, so you will not experience any failures due to Build version mismatches. If you would like to understand the various failures that you can see when Build versions are mismatched, look at leveraging one of the Window Server 1803 Hosts for this lab.

### Windows Server 1803 Host
---

You can connect to one of the provisioned Windows Server 1803 Hosts by using the ip address, username and password provided to you by the workshop coach.

Run the following in a Powershell prompt to RDP to the Windows Server 1803 Host. You will be prompted for your username and password.

```powershell
PS> mstsc /v <ip address>:3389
```

> Note: if you accidentally close the Command Prompt console in your RDP session, you can use the `Ctl+Shift+Esc` key combo to bring up the Task Manager. From `File > Run` in the Task Manager menu, you can start another Command Prompt console (`cmd`) or a PowerShell console (`powershell`).

## Part 1 - Run a Windows Server container

If you are running on a Windows 10 or Windows Server 1803 Host, then all of the following commands will work.

```powershell
# Run 1803 as a Windows Container and obtain the Windows Build information via ver
PS> docker run --rm microsoft/windowsservercore:1803 cmd /c ver

# Run 1803 as a Hyper-V Container and obtain the Windows Build information via ver
PS> docker run --rm --isolation=hyperv microsoft/windowsservercore:1803 cmd /c ver

# Run 1803 as a Windows Container and obtain the Windows Build information via Powershell
PS> docker run --rm microsoft/windowsservercore:1803 powershell [environment]::OSVersion.Version

# Run 1803 as a Windows Container and launch interactive Powershell shell
PS> docker run -it --rm microsoft/windowsservercore:1803 powershell
```

If you are running on Windows 10, then the following will work since the Windows 10 Host runs all Windows Containers in Hyper-V mode. If you are running on Windows Server 1803, then this command will fail due to a mismatch of Build (kernel) versions.

```powershell
# This will fail when run on Windows Server 1803 Host
PS> docker run --rm microsoft/windowsservercore:1709 cmd /c ver
```

You can get the command to work on a Windows Server 1803 Host by running as a Hyper-V container. This ensures that the Build (kernel) versions no longer need to match to run.

```powershell
# This will succeed when run on Windows Server 1803 Host
PS> docker run --isolation=hyperv --rm microsoft/windowsservercore:1709 cmd /c ver
```

## Part 2 - Run a console app in a Windows Container

You will now run a .NET console application in a Windows Container. The application we are running is available in GitHub:

- https://github.com/Microsoft/dotnet-framework-docker/tree/master/samples/dotnetapp

The Dockerfile that is used to build the Docker images we are running is available at:

- https://github.com/Microsoft/dotnet-framework-docker/blob/master/samples/dotnetapp/Dockerfile

You can view the available tags for the Docker images for the app and .NET Framework images at:

- https://hub.docker.com/r/microsoft/dotnet-framework-samples/tags/
- https://hub.docker.com/r/microsoft/dotnet-framework/tags/

Now you can run the following commands to see the app running against different Windows Server Container Builds.

```powershell
#
# On Windows 10 Host
#

# Run app using .NET 4.7 Framework on Windows Server 1803 base image
PS> docker run --rm microsoft/dotnet-framework-samples:dotnetapp-windowsservercore-1803

# Run app using .NET 4.7 Framework on Windows Server 1709 base image
PS> docker run --rm microsoft/dotnet-framework-samples:dotnetapp-windowsservercore-1709

# Run app using .NET Core Framework on Nano Server 1803 base image
PS> docker run --rm microsoft/dotnet-samples:dotnetapp-nanoserver-1803

#
# On Window Server 1803 Host
#

# Run app using .NET 4.7 Framework on Windows Server 1803 base image
PS> docker run --rm microsoft/dotnet-framework-samples:dotnetapp-windowsservercore-1803

# Run app using .NET 4.7 Framework on Windows Server 1709 base image. This requires Hyper-V isolation due
# to the mismatch of Build (kernel) versions between Container and Host OS
PS> docker run --rm --isolation=hyperv microsoft/dotnet-framework-samples:dotnetapp-windowsservercore-1709

# Run app using .NET Core Framework on Nano Server 1803 base image
PS> docker run --rm microsoft/dotnet-samples:dotnetapp-nanoserver-1803
```

> If you have apps that leverage .NET Framework you will need to leverage a Windows Server Core base image. If you have apps that leverage .NET Core, you can use a Nano Server base image.