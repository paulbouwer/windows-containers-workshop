Stop-Service docker -Force
dockerd --unregister-service
dockerd --register-service -H npipe:// -H 0.0.0.0:2375  
Start-Service docker
    
$daemonJson = '{"hosts": ["tcp://0.0.0.0:2375", "npipe://"] }'
$daemonJson | ConvertTo-Json | Out-File -Encoding ascii -FilePath C:\ProgramData\docker\config\daemon.json
