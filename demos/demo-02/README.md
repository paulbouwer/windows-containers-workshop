# Demo 2 - Windows Containers - Here be dragons!

## Identity

Run an ASP.NET website and demonstrate the process running as the ContainerAdministrator user.

```powershell
# Start the ASP.NET website
PS> docker run -d --rm -p 8000:80 --name aspnet_sample microsoft/dotnet-framework-samples:aspnetapp-windowsservercore-1803

# Hit the website to demonstrate that it is running
PS> (Invoke-WebRequest -UseBasicParsing -Uri http://localhost:8000).Content

# Exec into the running container and list the running processes and their owners
PS> docker cp c:/get-process-list.ps1 aspnet_sample:/get-process-list.ps1
PS> docker exec -it aspnet_sample powershell
PS> c:/get-process-list.ps1
PS> exit
```

## Background processes

Demonstrate how ServiceMonitor can be leveraged to ensure that background processes are made to behave like good container citizens.

Show that the following Dockerfile that builds the image we ran in the previous part leverages the `microsoft/aspnet` base image.

```dockerfile
# https://github.com/Microsoft/dotnet-framework-docker/blob/master/samples/aspnetapp/Dockerfile

...
FROM microsoft/aspnet:4.7.2 AS runtime
WORKDIR /inetpub/wwwroot
COPY --from=build /app/aspnetapp/. ./
```

The `microsoft/aspnet` image is build using the following Dockerfile.

```dockerfile
# https://github.com/Microsoft/aspnet-docker/blob/master/4.7.2-windowsservercore-1803/runtime/Dockerfile

FROM microsoft/dotnet-framework:4.7.2-runtime-windowsservercore-1803

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Add-WindowsFeature Web-Server; `
    Add-WindowsFeature NET-Framework-45-ASPNET; `
    Add-WindowsFeature Web-Asp-Net45; `
    Remove-Item -Recurse C:\inetpub\wwwroot\*; `
    Invoke-WebRequest -Uri https://dotnetbinaries.blob.core.windows.net/servicemonitor/2.0.1.3/ServiceMonitor.exe -OutFile C:\ServiceMonitor.exe

...

EXPOSE 80
ENTRYPOINT ["C:\\ServiceMonitor.exe", "w3svc"]

```

Run the following to demonstrate that the container running the ASP.NET website is still up and running.

```powershell
PS> while ($true) { docker container list; sleep 1 }
```

In another Powershell console, exec into the running container and stop the underlying IIS service (w3svc).

```powershell
PS> docker exec -it aspnet_sample powershell
PS> get-service w3svc
PS> stop-service w3svc
PS> get-service w3svc
```

You should see the `exec` session end and the `docker container list` return no enstry for the ASP.NET website. Because `ServiceMonitor` observed that the running state of the w3svc service had changed from `SERVICE_RUNNING`, it terminated the container process.