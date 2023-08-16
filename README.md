# Zero Trust and Azure Imaging

# PRE-REQS

# PRE-REQS

* Azure Bicep - https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep
* Azure PowerShell Modules - https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell?view=azps-10.2.0

All resources are assumed to be within the same resource group. Resources required before deployment
* Virtual Network
* Storage Account
* Private Endpoint (on storage account)
* Private DNS Zone
* Azure Compute Gallery
* Managed Identity with RBAC Roles - Storage Blob Data Owner (scoped at the storage account or resource group where the storage account is deployed)
* Any EXEs, scripts, etc. called during deployment uploaded to a storage account container

Example PowerShell to run the solution:
```
 $deploymentArguments = @{
         AdminUsername = 'xadmin'
         ContainerName ='artifacts'
         GalleryName = 'testGallery2'
         ImageName = 'developerImage'
         ImageOffer = 'windows-11'
         ImagePublisher = 'MicrosoftWindowsDesktop'
         ImageSku = 'win11-22h2-avd'
         ImageVersion = "9.12.2"
         InstallAccess =  $false
         InstallExcel =  $false
         InstallFsLogix =  $false
         InstallOneDriveForBusiness =  $false
         InstallOneNote =  $false
         InstallOutlook =  $false
         InstallPowerPoint =  $false
         InstallProject =  $false
         InstallPublisher =  $false
         InstallSkypeForBusiness =  $false
         InstallTeams =  $false
         InstallVirtualDesktopOptimizationTool =  $false
         InstallVisio =  $false
         InstallWord = $false
         Location = 'usgovvirginia'
         MiName = 'image-mi'
         OSVersion = 'win11-22h2-avd'
         ResourceGroupName = 'test2_group'
         SecurityType = 'TrustedLaunch'
         StorageAccountName = saimageartifacts
         StorageEndpoint = '.blob.core.usgovcloudapi.net'
         SubnetName = 'default'
         TenantType = 'GovernmentCommunityCloud'
         UserAssignedIdentityObjectId = '258d3674-d759-4fe1-bddf-13413e16a6a7'
         VirtualNetworkName = 'testtimage-vnet'
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
