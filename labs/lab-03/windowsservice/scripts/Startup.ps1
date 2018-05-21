param (
    [string]$serviceName
)

C:\windowsservice-startup\Set-AppConfigSettings.ps1 -appConfig c:\windowsservice\$serviceName.exe.config
Get-Service -Name $serviceName | Stop-Service
Get-Service -Name $serviceName | Start-Service

C:\ServiceMonitor.exe $serviceName