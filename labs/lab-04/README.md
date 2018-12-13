
# Lab 4 - Exploring Mixed Workloads in a kubernetes cluster

<!-- TOC -->

- [Part 1 - Creating the cluster with aks-engine](#part-1---creating-the-cluster-with-aks-engine)
- [Part 2 - Logging and Monitoring](#part-2---logging-and-monitoring)
  - [Logging](#logging)
  - [Monitoring](#monitoring)
- [Part 3 - Taints and Tolerations](#part-3---taints-and-tolerations---working-with-linux-and-windows-workloads)
- [Part 4 - Deploying an Ingress Controller](#part-4---deploying-an-ingress-controller)

<!-- /TOC -->

## Prereqs

- Azure subscription
- install [azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- install [helm](https://docs.helm.sh/using_helm/)
- install [aks-engine](https://github.com/Azure/aks-engine/releases/latest)
- ssh keys

## Part 1 - Creating the cluster with aks-engine

Aks-engine will allow us to create our kubernetes cluster with windows nodes. Before you follow this [walkthrough](https://github.com/Azure/aks-engine/blob/master/docs/topics/windows.md), make note that we will want to use the [windows/kubernetes-hybrid.json](https://github.com/Azure/aks-engine/blob/master/examples/windows/kubernetes-hybrid.json) apimodel to deploy a cluster with 2 Windows nodes, and 2 Linux nodes (5 total nodes, including the master) instead of the simple cluster with 2 Windows nodes.

[Learn more about Windows and Kubernetes](https://github.com/Azure/aks-engine/blob/master/docs/topics/windows-and-kubernetes.md)

> **Note**: Even when the pod status is **Ready**, IIS can be slow to start. You can warmup IIS requests with the following (exact number may vary depending on your app):
> ```yaml
> readinessProbe:
>   httpGet:
>     path: /
>     port: 80
>   timeoutSeconds: 3
>   periodSeconds: 10
>   initialDelaySeconds: 2
> livenessProbe:
>   httpGet:
>     path: /
>     port: 80
>   timeoutSeconds: 3
>   periodSeconds: 10
>   initialDelaySeconds: 300
> ```

## Part 2 - Logging and monitoring

### Logging

Now that you have a mixed-cluster up with a running service, let's look at logging. There are a few [considerations](https://gist.github.com/jsturtevant/73b0bfe301a6abecd951b6f98bddffd4) when thinking about logging options for windows workloads on kubernetes.

Similar to previous labs in this workshop, windows applications often maintain logs in files. In this lab, we will leverage [FluentD](https://github.com/fluent/fluentd) in order to observe these logs in a way that is more native to kubernetes, i.e via the ```kubectl logs``` command.

#### FluentD Configuraton

As it currently stands, Docker Automated builds do not support windows. For this reason, we will need to manually build and push to our own repo. In order to do so, you need to:

1. Get the latest Dockerfile from [here](https://github.com/fluent/fluentd-docker-image), by choosing the latest Windows Dockerfile. This [dockerfile](https://github.com/vyta/windows-containers-workshop/blob/kubernetes/labs/lab-04/logging/fluentD/Dockerfile) file is the latest FluentD Dockerfile for Windows as of Jan 7, 2019.
1. Copy the [fluent.conf](https://github.com/vyta/windows-containers-workshop/blob/kubernetes/labs/lab-04/logging/fluentD/fluent.conf) file to the same directory.

To configure FluentD to gather events from a file, we'll configure the ```tail``` input plugin to watch a directory for .log files, then to configure FluentD to output those events to stdout, we'll configure the ```stdout``` output plugin. The contents of your fluent.conf should look something like this:

```text
# configure input plugins using source directive
# NOTE: the path string must use '/' instead of '\'
<source>
  @type tail
  format none
  path C:/logs/*.log
  pos_file C:/fluentd_test.pos
  tag iis.*
  rotate_wait 5
  read_from_head true
  refresh_interval 60
</source>

# configure output plugins using match directive
<match iis.**>
  @type stdout
</match>
```

The base images of your app and the fluentd sidecar, need to be compatible. In this case, the IIS image is using windowsservercore-ltsc2019. Let's make this change in our Dockerfile:

```Dockerfile
FROM mcr.microsoft.com/windows/servercore:ltsc2019
...
```

Now you're ready to build and push your image:

```sh
# build locally (this could take a few minutes) and push to repo
docker build -t {repo}/fluentd-win:1.3 .
docker push {repo}/fluentd-win:1.3
```

#### Kubernetes deployment

Update the kubernetes [deployment](https://github.com/vyta/windows-containers-workshop/blob/kubernetes/labs/lab-04/logging/deployment/iis-with-logging.yaml#L33) with your newly pushed fluentd image. There are two main updates in this deployment:

1. The addition of the fluentd sidecar
1. A shared volume

```yaml
spec:
  containers:
  - name: iis
    image: mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2019
    resources:
      limits:
        cpu: 1
        memory: 800m
      requests:
        cpu: .1
        memory: 300m
    ports:
      - containerPort: 80
    volumeMounts:
    - mountPath: C:\inetpub\logs\LogFiles\w3svc1
      name: log-volume
  - name: fluentd
    image: {repo}/fluentd-win:1.3
    imagePullPolicy: Always
    volumeMounts:
    - mountPath: C:\logs
      name: log-volume
  volumes:
  - name: log-volume
    emptyDir: {}
```

Now you should be able to run ```kubectl logs -lapp=iis-with-logging -c fluentd``` to view iis events.

Example output:

```console
PS> kubectl logs -lapp=iis-2019-with-logging -c fluentd
2019-01-07 20:25:11 +0000 [info]: parsing config file is succeeded path="C:\\fluent\\conf\\fluent.conf"
2019-01-07 20:25:13 +0000 [info]: using configuration file: <ROOT>
  <match fluent.**>
    @type null
  </match>
  <source>
    @type tail
    format none
    path "C:/logs/*.log"
    pos_file "C:/fluentd_test.pos"
    tag "iis.*"
    rotate_wait 5
    read_from_head true
    refresh_interval 60
    <parse>
      @type none
    </parse>
  </source>
  <match iis.**>
    @type stdout
  </match>
</ROOT>
2019-01-07 20:25:13 +0000 [info]: starting fluentd-1.3.2 pid=20684 ruby="2.4.2"
2019-01-07 20:25:13 +0000 [info]: spawn command to main:  cmdline=["C:/ruby24/bin/ruby.exe", "-Eascii-8bit:ascii-8bit", "C:/ruby24/bin/fluentd", "-c", "C:\\fluent\\conf\\fluent.conf", "--under-supervisor"]
2019-01-07 20:25:18 +0000 [info]: gem 'fluentd' version '1.3.2'
2019-01-07 20:25:18 +0000 [info]: adding match pattern="fluent.**" type="null"
2019-01-07 20:25:18 +0000 [info]: adding match pattern="iis.**" type="stdout"
2019-01-07 20:25:18 +0000 [info]: adding source type="tail"
2019-01-07 20:25:18 +0000 [info]: #0 starting fluentd worker pid=19804 ppid=20684 worker=0
2019-01-07 20:25:18 +0000 [info]: #0 fluentd worker is now running worker=0
2019-01-07 20:26:18 +0000 [info]: #0 following tail of C:/logs/u_ex190107.log
2019-01-07 20:26:39.561234000 +0000 iis.C:.logs.u_ex190107.log: {"message":"#Software: Microsoft Internet Information Services 10.0"}
2019-01-07 20:26:39.561234000 +0000 iis.C:.logs.u_ex190107.log: {"message":"#Version: 1.0"}
2019-01-07 20:26:39.561234000 +0000 iis.C:.logs.u_ex190107.log: {"message":"#Date: 2019-01-07 20:26:01"}
2019-01-07 20:26:39.561234000 +0000 iis.C:.logs.u_ex190107.log: {"message":"#Fields: date time s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs(User-Agent) cs(Referer) sc-status sc-substatus sc-win32-status time-taken"}
2019-01-07 20:26:39.561234000 +0000 iis.C:.logs.u_ex190107.log: {"message":"2019-01-07 20:26:01 10.240.0.85 GET / - 80 - 10.240.0.65 Mozilla/5.0+(Windows+NT+10.0;+Win64;+x64)+AppleWebKit/537.36+(KHTML,+like+Gecko)+Chrome/64.0.3282.140+Safari/537.36+Edge/18.17763 - 200 0 0 714"}
2019-01-07 20:26:39.561234000 +0000 iis.C:.logs.u_ex190107.log: {"message":"2019-01-07 20:26:01 10.240.0.85 GET /iisstart.png - 80 - 10.240.0.65 Mozilla/5.0+(Windows+NT+10.0;+Win64;+x64)+AppleWebKit/537.36+(KHTML,+like+Gecko)+Chrome/64.0.3282.140+Safari/537.36+Edge/18.17763 http://40.85.160.140/ 200 0 0 287"}
```

### Monitoring

It is important to observe and monitor the health of your cluster. There are a few options available for monitoring Kubernetes cluster, some of the main ones are highlighted [here](https://github.com/Azure/aks-engine/blob/master/docs/topics/monitoring.md). In this part of the lab, we will be looking at Azure Monitor (formerly Operations Management Suite) as well as how Windows Management Instrumentation can be leveraged to export metrics to Prometheus.

#### Container Insights and Log Analytics

Azure Monitor allows you to monitor, analyze, and visualize the health of all your Azure applications and services whereever they are hosted in one location. You can learn more about Azure Monitor for Containers [here](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/container-insights-overview).

Follow the steps [here](https://github.com/Microsoft/OMS-docker/tree/aks-engine) to add Azure Monitoring for Containers to your cluster.
> **Tip**: Leverage the [AddAzureMonitor-Containers.ps1](https://raw.githubusercontent.com/vyta/windows-containers-workshop/blob/kubernetes/labs/lab-04/monitoring/AddAzureMonitor-Containers.ps1) when adding the Container Insights Solution to your workspace.

Now you should see data from your linux nodes. There currently isn't a containerized omsagent for windows, so there is additional work needed to get those nodes up to speed:

[Installing OMS Agent on Master Node](https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/azure-monitor/insights/containers.md#install-and-configure-windows-container-hosts):

  1. First we need to prep the windows nodes before installing the agent:
      - RDP into each Windows Node:
        ```bash
        PS> ssh -L 5500:<node-ip>:3389 <linuxuser>@<clustername>.<region>.cloudapp.azure.com

        # Launch RDP to connect to localhost:5500 and use Windows credentials to login
        ```
      - Then run the prep script:
         ```bash
        PS> powershell Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/vyta/windows-containers-workshop/blob/kubernetes/labs/lab-04/monitoring/PrepWindowsNodesForAzMon.ps1 -OutFile PrepWindowsNodesForAzMon.ps1
        PS> powershell .\PrepWindowsNodesForAzMon.ps1
        ```
  1. Then to install the Windows Agents on our Windows Nodes:
      1. In the Azure portal, click **All services** found in the upper left-hand corner. In the list of resources, type **Log Analytics**. As you begin typing, the list filters based on your input. Select **Log Analytics**.
      1. In your list of Log Analytics workspaces, select the workspace created earlier.
      1. On the left-hand menu, under Workspace Data Sources, click **Virtual machines**.
      1. In the list of **Virtual machines**, select a virtual machine you want to install the agent on. Notice that the **Log Analytics connection status** for the VM indicates that it is **Not connected**.
      1. In the details for your virtual machine, select **Connect**. The agent is automatically installed and configured for your Log Analytics workspace. This process takes a few minutes, during which time the **Status** is **Connecting**.
      1. After you install and connect the agent, the **Log Analytics connection status** will be updated with **This workspace**.

  1. Data collection:
      1. Select **Advanced settings** from the menu on the left in your workspace.
      1. Select **Data**, and then select **Windows Event Logs**.  
      1. You add an event log by typing in the name of the log.  Type **System** and then click the plus sign **+**.  
      1. In the table, check the severities **Error** and **Warning**.
      1. Click **Save** at the top of the page to save the configuration.
      1. Select **Windows Performance Data** to enable collection of performance counters on a Windows computer. 
      1. When you first configure Windows Performance counters for a new Log Analytics workspace, you are given the option to quickly create several common counters. They are listed with a checkbox next to each. Click **Add the selected performance counters**.  They are added and preset with a ten second collection sample interval.
      1. Click **Save** at the top of the page to save the configuration.

## Part 3 - Taints and Tolerations - Working with Linux and Windows Workloads

Notice in parts 1 and 2, the deployment is set to assign pods to certain nodes using *nodeSelector*. The pods were assigned to whichever node had the label that was specified as a key-value pair in the *nodeSelector* field. To see the full list of labels on a given node, use `kubectl describe node <node-name>`. This is sufficient to ensure windows workloads are scheduled on windows nodes. We can do a similar thing to linux workloads to make sure they are scheduled appropriately. This would mean that any future workload deployed to your cluster will need a nodeSelector, and all past workloads will need to be changed to include the *nodeSelector*. Instead of having to make modifications to *both* Linux and Windows workloads, let's limit it to one. Since we are already adding the *nodeSelector* to Windows workloads, we can additionally taint windows nodes and add tolerations to windows workloads to ensure no changes need to be made to Linux workloads.

Tainting the windows nodes with the NoSchedule effect, prevents pods from being scheduled on the nodes unless a matching toleration is provided in the PodSpec.

To taint a node:

```console
PS > kubectl taint node <node-name> beta.kubernetes.io/os=windows:NoSchedule
```

To add Toleration to PodSpec of windows workloads:

```yaml
tolerations:
- key: "beta.kubernetes.io/os"
  operator: "Equals"
  value: "windows"
  effect: "NoSchedule"
```

This way, linux workloads can be deployed without any changes.

## Part 4 - Deploying an Ingress Controller

The final part of this lab is to use an ingress controller to route traffic to workloads running in your cluster, both Windows and Linux.

  1. Create [Linux](https://github.com/vyta/windows-containers-workshop/blob/kubernetes/labs/lab-04/ingress/linux-deployment.yaml) and [Windows](https://github.com/vyta/windows-containers-workshop/blob/kubernetes/labs/lab-04/ingress/windows-deployment.yaml) services using `kubectl create -f [linux/windows]-deployment.yaml`.
  1. Configure helm and setup NGINX:
      ```console
      PS> helm init --upgrade --node-selectors "beta.kubernetes.io/os=linux"

      PS> helm install --name nginx-ingress --set controller.nodeSelector."beta\.kubernetes\.io\/os"=linux --set defaultBackend.nodeSelector."beta\.kubernetes\.io\/os"=linux --set rbac.create=true stable/nginx-ingress
      ```
      Check that all pods are ready:
      ```console
      PS> kubectl get pods
      NAME                                             READY     STATUS    RESTARTS
      iis-2019-5844957c4b-65r9v                        1/1       Running   0
      nginx-6459f89666-jnzvl                           1/1       Running   0
      nginx-ingress-controller-7d794c46f9-v2jjl        1/1       Running   0
      nginx-ingress-default-backend-6688d8694d-tr5kg   1/1       Running   0
      ```
  1. Edit the [ingress rule](https://github.com/vyta/windows-containers-workshop/blob/kubernetes/labs/lab-04/ingress/ingress.yaml) with a hostname you manage or for now, you can use your cluster's FQDN and create the ingress rule using `kubectl create -f ingress.yaml`
  1. Test the ingress rule:
      Get the external IP of your ingress controller:
      ```console
      PS> kubectl get svc nginx-ingress-controller
      NAME                       TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)
      nginx-ingress-controller   LoadBalancer   10.0.179.43   13.90.247.55   80:32403/TCP,443:32286/TCP
      ```
      Test using `Invoke-WebRequest http://<external-ip>/<path> -Headers @{"Host"="<hostname>"}`:
      ```console
      PS> Invoke-WebRequest http://13.90.247.55 -Headers @{"Host"="aks-engine.eastus.cloudapp.com"}
      StatusCode        : 200
      Content           : <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
                          <html xmlns="http://www.w3.org/1999/xhtml">
                          <head>
      RawContent        : HTTP/1.1 200 OK
                          Connection: keep-alive
                          Vary: Accept-Encoding
                          Accept-Ranges: bytes
                          Content-Length: 703
                          Content-Type: text/html
                          ETag: "a14e5dd1baa7d41:0"
                          Last...
      ```
      ```console
      PS> Invoke-WebRequest http://13.90.247.55/linux -Headers @{"Host"="aks-engine.eastus.cloudapp.com"}
      StatusCode        : 200
      StatusDescription : OK
      Content           : <!DOCTYPE html>
                          <html>
                          <head>
                          <title>Welcome to nginx!</title>
                          <style>
                              body {
                                  width: 35em;
                                  margin: 0 auto;
                                  font-family: Tahoma, Verdana, Arial, sans-serif;
                              }
                          </style>
                          <...
      RawContent        : HTTP/1.1 200 OK
                          Connection: keep-alive
                          Vary: Accept-Encoding
                          Accept-Ranges: bytes
                          Content-Length: 612
                          Content-Type: text/html
                          Date: Mon, 28 Jan 2019 21:37:50 GMT
                          ETag: "5c21fedf-264"
                          Last-Modi...
      ```
