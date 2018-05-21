FROM microsoft/aspnet:4.7.2-windowsservercore-1803

WORKDIR /inetpub/wwwroot
COPY src .
