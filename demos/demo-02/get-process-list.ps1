# https://github.com/StefanScherer/dockerfiles-windows/blob/master/windows-service/ps.ps1

$owners = @{}
gwmi win32_process |% {$owners[$_.handle] = $_.getowner().user}

get-process | select processname,Id,@{l="Owner";e={$owners[$_.id.tostring()]}}