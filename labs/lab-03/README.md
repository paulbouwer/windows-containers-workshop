# Lab 3 - Exploring Windows Services 

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

## Part 1 - Run a Windows Service in a Windows Container

There is a simple Windows Service that will be used to demonstrate the next set of concepts. There is no need to compile anything as the compiled binaries have been included with this lab. The source code is there if you wish to modify and explore further.

Look inside the `windows-service\src\WorkshopService` folder and familiarise yourself with the following:

**App.config**

The `Message` App Setting and `DBConnection` Connection String values will be written out to the log file. The `LogLocation` App Setting value will be used as the location to write the log file.

```xml
<configuration>
  <appSettings>
    <appSettings>
    <add key="Message" value="Hello from Windows Service." />
    <add key="LogLocation" value="C:\\windowsservice\\" />
  </appSettings>
  ...
  <connectionStrings>
    <add name="DBConnection" connectionString="This is the default connection string." providerName="System.Data.SqlServerCe.4.0" />
  </connectionStrings>
  ...
</configuration
```
**WorkshopService.cs**

The NLog logger is initialised in the Windows Service constructor. NLog is leveraged to write log entries to the location described by the `LogLocation` App Setting value.

```csharp
public WorkshopService()
{
  var config = new NLog.Config.LoggingConfiguration();
  var logfile = new NLog.Targets.FileTarget() { FileName = System.Configuration.ConfigurationManager.AppSettings["LogLocation"] + "log.txt", Name = "logfile", Layout = "${longdate}|${level:uppercase=true}|${logger}|${message}" };
  config.LoggingRules.Add(new NLog.Config.LoggingRule("*", NLog.LogLevel.Debug, logfile));
  NLog.LogManager.Configuration = config;
}
```

Log entries (which include the `Message` App Setting and `DBConnection` Connection String values) are written to the log file.


``` csharp
protected override void OnStart(string[] args)
{
  var logger = NLog.LogManager.GetCurrentClassLogger();

  logger.Info("OnStart: Hello from inside a container.");
  logger.Info("App Settings: Message: {0}", System.Configuration.ConfigurationManager.AppSettings["Message"]);
  logger.Info("Connection Strings: DBConnection: {0}", System.Configuration.ConfigurationManager.ConnectionStrings["DBConnection"]);
}

protected override void OnStop()
{
  var logger = NLog.LogManager.GetCurrentClassLogger();

  logger.Info("OnStop: Goodbye from inside a container.");
}
```

### Run the Windows Service
---

Build the Docker image from the source code and binaries available under `windowsservce\src` using `Step1.Dockerfile`.

Ensure you understand all the aspects of `Step1.Dockerfile`.

```powershell
PS> cd windowsservce
PS> docker build -t workshop/windowsservice:step1 -f Step1.Dockerfile .
```

Then run a container based on the Docker image you have just built.

```powershell
PS> docker run --rm --name workshop_windowsservice_step1 -d workshop/windowsservice:step1
```

Now, exec into the running container so that you can verify that the log file was written with the correct entries and to the correct location. The values you see should be those that are defined in the `App.config`.

```powershell
PS> docker exec -it workshop_windowsservice_step1 powershell

# You should see a status of Running for the WorkshopService
container> get-service |? { $_ -match "WorkshopService"}

# You should see a log.txt log file in the C:\windowsservice folder
container> dir C:\windowsservice 

# You should see the following entries in the log file.
# OnStart: Hello from inside a container.
# App Settings: Message: Hello from Windows Service.
# Connection Strings: DBConnection: This is the default connection string.
container> cat C:\windowsservice\log.txt

# You should see all the WorkshopService Windows Service files and assemblies here
# Note that the App.config is renamed to WorkshopService.exe.config
container> dir C:\windowsservice

# Validate the values you expect in the WorkshopService.exe.config file.
container> cat C:\windowsservice\WorkshopService.exe.config

# exit the exec session
container> exit
```

## Part 2 - Run a Windows Service in a Windows Container with config updates and volume mapping

Most customers are content during lift and shift to continue to bundle their config with the final packaging, in this case the container. This is what we did previously in Part 1.

This is not a very container native approach, where typically the same image is leveraged across environments and secrets & config are injected by the orchestrator or docker.

In this part of the lab, we will explore the same pattern from Lab 2 and look at how this can be leveraged in the context of a Windows Service.

### Run the Windows Service
---

Now we are going to build a new Docker image and run a container based on it. You will leverage environment variables with the `APPSETTING_` and `CONNSTR_` prefixes to override the values in the `App.config` file. You will also add a folder on your host and map a volume in the container to this folder so that your log files will persist outside of the lifecycle of your container. This also opens up support for host based agents that will collate and forward your logs.

Build the Docker image from the source code and binaries available under `windowsservce\src` using `Step2.Dockerfile`.

Ensure you understand all the aspects of `Step2.Dockerfile`.

```powershell
PS> cd windowsservce
PS> docker build -t workshop/windowsservice:step2 -f Step2.Dockerfile .
```

You will need to create a `C:\container-logs` folder on your host. 

Now run the container with the environment variables for overriding the `Message` and `LogLocation` App Settings and the `DBConnection` Connection String. You will then leverage a volume to mount the new `C:\workshop\logs` logfile location in the container to the `C:\container-logs` folder on the host.

```powershell
PS> docker run --rm --name workshop_windowsservice_step2 -d -e APPSETTING_Message="Hello from the environment" -e APPSETTING_LogLocation="C:\\workshop\\logs\\" -e CONNSTR_DBConnection="DBConnection
 from the environment." -v c:\container-logs:c:\workshop\logs workshop/windowsservice:step2
```

Now, exec into the running container so that you can verify that the log file was written with the correct entries and to the correct location. The values you see should be those that are defined in the `App.config`.

```powershell
PS> docker exec -it workshop_windowsservice_step2 powershell

# You should see a status of Running for the WorkshopService
container> get-service |? { $_ -match "WorkshopService"}

# You should see a log.txt log file in the c:\workshop\logs folder, not the C:\windowsservice folder
container> dir c:\workshop\logs 

# You should see the following entries in the log file.
# OnStart: Hello from inside a container.
# App Settings: Message: Hello from the environment.
# Connection Strings: DBConnection: DBConnection from the environment.
container> cat c:\workshop\logs\log.txt

# You should see all the WorkshopService Windows Service files and assemblies here
# Note that the App.config is renamed to WorkshopService.exe.config
container> dir C:\windowsservice

# Validate the values in the WorkshopService.exe.config file are updated from the environment variables.
container> cat C:\windowsservice\WorkshopService.exe.config

# Stop the WorkshopService Windows Service. The ServiceMonitor at this point should terminate the container.
# You should lose your exec session.
container> Get-Service -Name WorkshopService | Stop-Service 
```

The log file should also be available on your host. You should see a final log entry from the OnStop method in the log file.

```powershell
# You should see a log.txt log file in C:\container-logs on the host
PS> dir C:\container-logs

# You should see the following final entry in the log file written by the OnStop method.
# OnStop: Goodbye from inside a container.
PS> cat C:\container-logs\log.txt
```
