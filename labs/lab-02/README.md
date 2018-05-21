# Lab 2 - Exploring IIS and ASP.NET Websites 

## Notes

In this workshop there are two environments that you can run this lab in.

### Windows 10 Host with Docker for Windows
---

You will be able to access the running container based web apps in your browser.

If you are running Docker for Windows Edge 18.x, use:

```
http://host.docker.local:<port>
```

otherwise you will have have to get the ip addres as follows and leverage that:

```powershell
PS> docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" <container-id>
```

### Windows Server 1803 Host
---

The follow ports are open on the provisioned Windows Server 1803 Hosts to support running the web apps in this lab and accessing them via your browser:

- 8080
- 8081

## Part 1 - Run IIS in a Windows Container

You will now run the IIS image in a Windows Container. The Dockerfile that is used to build the `microsoft/iis` Docker image we are running is available at:

- https://github.com/Microsoft/iis-docker/blob/master/windowsservercore-1803/Dockerfile

Start the container as follows:

```powershell
PS> docker run --rm --name iis -d -p 8080:80 microsoft/iis 
```

Browse to the website on port `8080` as is appropriate for your host environment. You will see the standard IIS Start page.

If you exec into the running container and look at the `C:\inetpub\wwwroot` folder you will see the `iisstart.htm` and `iisstart.png` assets which are used to present the IIS Start page.

```powershell
PS> docker exec -it iis powershell

# You should see iisstart.htm and iisstart.png in the C:\inetpub\wwwroot folder
container> dir C:\inetpub\wwwroot

# exit the exec session
container> exit
```

Stop the container so we can free up the port on the host for the next parts of this lab.

```powershell
PS> docker container stop iis
```

## Part 2 - Run an ASP.NET Web Site in a Windows Container

There is a simple ASP.NET Web Site (Razor) that will be used to demonstrate the next set of concepts. There is no need to compile anything as the compiled binaries have been included with this lab. The source code is there if you wish to modify and explore further.

Look inside the `website\aspnet_website\src` folder and familiarise yourself with the following:

**Web.config**

The `Message` App Setting and `DBConnection` Connection String values will be displayed on the Default page. The `LogLocation` App Setting value will be used as the location to write the log files.

```xml
<configuration>
  <appSettings>
    <add key="Message" value="Hello from ASP.NET Website." />
    <add key="LogLocation" value="C:\\aspnet\\" />
  </appSettings>
  ...
  <connectionStrings>
    <add name="DBConnection" connectionString="This is the default connection string." providerName="System.Data.SqlServerCe.4.0" />
  </connectionStrings>
  ...
</configuration
```

**Default.cshtml**

The `Message` App Setting and `DBConnection` Connection String values are retrieved and displayed.

```html
<h1>App Settings</h1>
<p>
  <strong>Message:</strong> @System.Web.Configuration.WebConfigurationManager.AppSettings["Message"]
</p>
<h1>Connection Strings</h1>
<p>
  <strong>DBConnection:</strong> @System.Web.Configuration.WebConfigurationManager.ConnectionStrings["DBConnection"]
</p>
```

The NLog logger is leveraged to write a log entry to the location described by the `LogLocation` App Setting value.

```csharp
var config = new NLog.Config.LoggingConfiguration();
var logfile = new NLog.Targets.FileTarget() { FileName = System.Web.Configuration.WebConfigurationManager.AppSettings["LogLocation"] + "log.txt", Name = "logfile", Layout = "${longdate}|${level:uppercase=true}|${logger}|${message}" };
config.LoggingRules.Add(new NLog.Config.LoggingRule("*", NLog.LogLevel.Debug, logfile));
NLog.LogManager.Configuration = config;

var logger = NLog.LogManager.GetCurrentClassLogger();
logger.Info("Hello from inside a container.");
```

### Run the ASP.NET Web Site
---

Build the Docker image from the source code and binaries available under `website\aspnet_website\src`.

```powershell
PS> cd website\aspnet_website
PS> docker build -t workshop/website:step1 -f Step1.Dockerfile .
```

Then run a container based on the Docker image you have just built.

```powershell
PS> docker run --rm --name workshop_website_step1 -d -p 8080:80 workshop/website:step1
```

Browse to the website on port `8080` as is appropriate for your host environment. You should see *App Settings > Message* displayed with a value of `Hello from ASP.NET Website.` and *Connection Strings > DBConnection* with a value of `This is the default connection string.`. These are the values defined in the `Web.config`.

Now, exec into the running container so that you can verify that the log file was written to the correct location.

```powershell
PS> docker exec -it workshop_website_step1 powershell

# You should see a log.txt log file in the C:\aspnet folder
container> dir C:\aspnet 

# You should see a "Hello from inside a container." entry in the log file.
container> cat C:\aspnet\log.txt

# If you had a problem viewing the web site in your browser, you can do a local GET to validate 
# the displayed values
container> (Invoke-WebRequest -Uri http://localhost:8080 -UseBasicParsing).Content

# exit the exec session
container> exit
```

Stop the container so we can free up the port on the host for the next parts of this lab.

```powershell
PS> docker container stop workshop_website_step1
```

## Part 3 - Run an ASP.NET Web Site in a Windows Container with config updates

Most customers are content during lift and shift to continue to bundle their config with the final packaging, in this case the container. This is what we did previously in Part 2.

This is not a very container native approach, where typically the same image is leveraged across environments and secrets & config are injected by the orchestrator or docker.

In this part of the lab, we will explore a pattern that can be leveraged to allow you to override values in the Web.config.

### Build a new base image
---

We will first build a new base image that we will use for our ASP.NET Web Site going forward. This base image is based on the `microsoft/aspnet:4.7.2-windowsservercore-1803` image.

We will add the ability to support Web Config transforms (Web.Release.config, Web.Debug.config) and also the ability to override App Settings and the Connection String at runtime. This is based on some great work by Anthony Chu - you can read more details at:

- https://anthonychu.ca/post/overriding-web-config-settings-environment-variables-containerized-aspnet-apps/
- https://github.com/anthonychu/aspnet-env-docker

The `Startup.ps1` script is used to perform the overrides and then call ServiceMonitor on the `w3svc` service to exit block and monitor the container.

Build the Docker image from the Dockerfile available under `website\aspnet_config_env`.

```powershell
PS> cd website\aspnet_config_env
PS> docker build -t workshop/aspnet:4.7.2-windowsservercore-1803 .
```

### Run the ASP.NET Web Site and override config values at runtime
---

We will build a new Docker image from the source code and binaries available under `website\aspnet_website\src` that leverages the `workshop/aspnet:4.7.2-windowsservercore-1803` base image we just built.

Have a look at the `Step2.Dockerfile` in `website\aspnet_website`. Also understand that we have not changed the values in the `Web.config` file under `website\aspnet_website\src`.

```powershell
PS> cd website\aspnet_website
PS> docker build -t workshop/website:step2 -f Step2.Dockerfile .
```

Then run a container based on the Docker image you have just built. You will leverage environment variables with the `APPSETTING_` and `CONNSTR_` prefixes to override the values in the `Web.config` file.

```powershell
PS> docker run --rm --name workshop_website_step2 -d -p 8080:80 -e APPSETTING_Message="Hello from the environment." -e CONNSTR_DBConnection="DBConnection from the environment." workshop/website:step2
```

Browse to the website on port `8080` as is appropriate for your host environment. You should see *App Settings > Message* displayed with the modified value of `Hello from the environment.` and *Connection Strings > DBConnection* with a value of `DBConnection from the environment.`. These are the values defined in the environment variables at runtime and have overriden the values defined in `Web.config`.

## Part 4 - Run an ASP.NET Web Site in a Windows Container with log file volume mounting

Now we are going to run another container based on the same Docker image you have just built. You will leverage environment variables with the `APPSETTING_` and `CONNSTR_` prefixes to override the values in the `Web.config` file. You will also add a folder on your host and map a volume in the container to this folder so that your log files will persist outside of the lifecycle of your container. This also opens up support for host based agents that will collate and forward your logs.

### Run the ASP.NET Web Site, override config values at runtime and mount a volume for the log file
---

You will need to create a `C:\container-logs` folder on your host. 

Now run the container with the environment variables for overriding the `Message` and `LogLocation` App Settings and the `DBConnection` Connection String. You will then leverage a volume to mount the new `C:\workshop\logs` logfile location in the container to the `C:\container-logs` folder on the host.

```powershell
PS> docker run --rm --name workshop_website_step2 -d -p 8081:80 -e APPSETTING_Message="Hello from the environment." -e CONNSTR_DBConnection="DBConnection from the environment." -e APPSETTING_LogLocation="C:\\workshop\\logs\\" -v c:\container-logs:c:\workshop\logs workshop/website:step2
```

Browse to the website on port `8081` as is appropriate for your host environment. You should still see the *App Settings > Message* displayed with the modified value of `Hello from the environment.` and *Connection Strings > DBConnection* with a value of `DBConnection from the environment.`. These are the values defined in the environment variables at runtime and have overriden the values defined in `Web.config`.

Now, exec into the running container so that you can verify that the log file was written to the correct location.

```powershell
PS> docker exec -it workshop_website_step2 powershell

# You should see a log.txt log file in the C:\workshop\logs folder and no longer the C:\aspnet folder
container> dir C:\aspnet 
container> C:\workshop\logs

# You should see a "Hello from the environment." entry in the log file.
container> cat C:\workshop\logs\log.txt

# If you had a problem viewing the web site in your browser, you can do a local GET to validate 
# the displayed values
container> (Invoke-WebRequest -Uri http://localhost:8080 -UseBasicParsing).Content

# exit the exec session
container> exit
```

The log file should also be available on your host.

```powershell
PS> dir C:\container-logs
PS> cat C:\container-logs\log.txt
```
