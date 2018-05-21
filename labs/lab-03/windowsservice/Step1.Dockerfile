# escape=`

FROM microsoft/windowsservercore:1803

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

WORKDIR /windowsservice
COPY src/WorkshopService/bin/Debug .

RUN \Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe .\WorkshopService.exe /LogToConsole=true; `
    Get-Service -Name WorkshopService | Start-Service; `
    Start-BitsTransfer -Source https://dotnetbinaries.blob.core.windows.net/servicemonitor/2.0.1.3/ServiceMonitor.exe -Destination C:\ServiceMonitor.exe;

ENTRYPOINT ["C:\\ServiceMonitor.exe", "WorkshopService"]
