$subscriptionId = "<Azure-Subscription-Id>"
$workspaceResourceGroup = "<Your-Resource-Group>"
$workspaceName = "<Name-of-your-Log-Analytics-Workspace"
$region = "<Workspace-region>"

$workspaceResourceId = "/subscriptions/$($subscriptionId)/resourceGroups/$($workspaceResourceGroup)/providers/Microsoft.OperationalInsights/workspaces/$($workspaceName)"

Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/Microsoft/OMS-docker/ci_feature_prod/docs/templates/azuremonitor-containerSolution.json -OutFile azuremonitor-containerSolution.json
Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/Microsoft/OMS-docker/ci_feature_prod/docs/templates/azuremonitor-containerSolutionParams.json -OutFile azuremonitor-containerSolutionParams.json

$inJson = Get-Content .\azuremonitor-containerSolutionParams.json | ConvertFrom-Json
$inJson.parameters.workspaceResourceId.value = $workspaceResourceId
$inJson.parameters.workspaceRegion.value = $region

$inJson | ConvertTo-Json | Out-File -Encoding ascii -FilePath .\azuremonitor-containerSolutionParams.json

az group deployment create --resource-group $workspaceResourceGroup --template-file .\azuremonitor-containerSolution.json --parameters .\azuremonitor-containerSolutionParams.json