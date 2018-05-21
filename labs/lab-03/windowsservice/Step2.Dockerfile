# escape=`

FROM microsoft/windowsservercore:1803

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR /windowsservice
COPY src/WorkshopService/bin/Debug .

RUN \Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe .\WorkshopService.exe /LogToConsole=true; `    
    Start-BitsTransfer -Source https://dotnetbinaries.blob.core.windows.net/servicemonitor/2.0.1.3/ServiceMonitor.exe -Destination C:\ServiceMonitor.exe; `
    New-Item -Path \windowsservice-startup -ItemType Directory

COPY scripts c:/windowsservice-startup
ENTRYPOINT ["powershell.exe", "c:\\windowsservice-startup\\Startup.ps1", "WorkshopService"]
