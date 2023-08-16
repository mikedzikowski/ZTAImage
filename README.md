# Zero Trust and Azure Imaging

# PRE-REQS

# PRE-REQS

* Azure Bicep - https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep
* Azure PowerShell Modules - https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell?view=azps-10.2.0

All resources are assumed to be within the same resource group. Resources required before deployment
* Existing Virtual Network
* Existing Storage Account
* Existing Private Endpoint (on storage account)
* Existing Private DNS Zone
* Existing Azure Compute Gallery
* Existing Managed Identity with RBAC Roles - Storage Blob Data Owner (scoped at the storage account or resource group where the storage account is deployed)
* Any EXEs, scripts, etc. called during deployment uploaded to a storage account container

Example PowerShell to run the solution:
```
 $deploymentArguments = @{
         AdminUsername = 'xadmin'
         ContainerName ='artifacts'
         GalleryName = 'imageGallery'
         ImageName = 'developerImage'
         ImageOffer = 'windows-11'
         ImagePublisher = 'MicrosoftWindowsDesktop'
         ImageSku = 'win11-22h2-avd'
         ImageVersion = "1.0.0"
         InstallAccess =  $false
         InstallExcel =  $false
         InstallFsLogix =  $false
         InstallOneDriveForBusiness =  $false
         InstallOneNote =  $false
         InstallOutlook =  $true
         InstallPowerPoint =  $false
         InstallProject =  $false
         InstallPublisher =  $false
         InstallSkypeForBusiness = $false
         InstallTeams =  $false
         InstallVirtualDesktopOptimizationTool = $false
         InstallVisio = $false
         InstallWord = $true
         Location = 'eastus'
         MiName = 'image-mi'
         OSVersion = 'win11-22h2-avd'
         ResourceGroupName = 'rg-image-eastus2'
         SecurityType = 'TrustedLaunch'
         StorageAccountName = 'imagestorageaccount'
         StorageEndpoint = '.blob.core.windows.net'
         SubnetName = 'default'
         TenantType = 'Commercial'
         UserAssignedIdentityObjectId = '00000000-0000-0000-0000-000000000000'
         VirtualNetworkName = 'vnet-eastus-1'
         VmName = 'vm-image'
         VmSize = 'Standard_D2s_v5'
    }

.\New-VMImage.ps1 @deploymentArguments -Verbose
```

Example of how to view and troubleshoot the status of runcommands:
```
PS C:\git\ztaimage> $x = Get-AzVMRunCommand -ResourceGroupName rg-image -VMName vm-image -RunCommandName office -Expand InstanceView
PS C:\git\ztaimage> $x.InstanceView


ExecutionState   : Running
ExecutionMessage :
ExitCode         : 0
Output           :
Error            :
StartTime        : 8/2/2023 2:14:27 PM
EndTime          :
Statuses         :
```

# ADDITIONAL DOCUMENTATION IN PROGRESS
