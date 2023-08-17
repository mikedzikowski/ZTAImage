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
```powershell
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

## PARAMETERS

### -AdminUsername
Specifies the local administrator user name of the virtual machine that will be captured.
```yaml
Type: String
```
### -ContainerName
Specifies the container name where files, and scripts will be uploaded and consumed during the image process.
```yaml
Type: String
```
### -GalleryName
Specifies the existing Azure Image Gallery where the image will be created.
```yaml
Type: String
```
### -ImageName
Specifies the name of the image that will created.
```yaml
Type: String
```
### -ImageOffer
Specifies the name of the image offer of the image that will be created.
```yaml
Type: String
```
### -ImagePublisher
Specifies the name of the image publisher of the image that will be created.
```yaml
Type: String
```
### -ImageSku
Specifies the name of the image SKU of the image that will be created.
```yaml
Type: String
```
### -ImageVersion
Specifies the name of the image version of the image that will be created.
```yaml
Type: String
```
### -InstallAccess
Specifies if Access will be installed on the image created.
```yaml
Type: Boolean
```
### -InstallExcel
Specifies if Excel will be installed on the image created.
```yaml
Type: Boolean
```
### -InstallFsLogix
Specifies if FsLogix will be installed on the image created.
```yaml
Type: Boolean
```
### -InstallFsLogix
Specifies if FsLogix will be installed on the image created.
```yaml
Type: Boolean
```
### -InstallOneDriveForBusiness
Specifies if OneDrive For Business will be installed on the image created.
```yaml
Type: Boolean
```
### -InstallOneNote
Specifies if OneNote will be installed on the image created.
```yaml
Type: Boolean
```
### -InstallPowerPoint
Specifies if PowerPoint will be installed on the image created.
```yaml
Type: Boolean
```
### -InstallPublisher
Specifies if Publisher will be installed on the image created.
```yaml
Type: Boolean
```
### -InstallTeams
Specifies if Teams will be installed on the image created.
```yaml
Type: Boolean
```
### -InstallVirtualDesktopOptimizationTool

Specifies if Virtual Desktop Optimization Tool (VDOT) will be installed on the image created.
```yaml
Type: Boolean
```
### -InstallVisio
Specifies if Visio will be installed on the image created.
```yaml
Type: Boolean
```
### -InstallWord
Specifies if Word will be installed on the image created.
```yaml
Type: Boolean
```
### -Location
Specifies a location for the resources of the solution to be deployed.
```yaml
Type: String
```
### -MiName
Specifies the name of an existing managed identity to be used during deployment of the solution.
```yaml
Type: String
```
### -OSVersion
Specifies the OS Version of the image to be captured.
```yaml
Type: String
```
### -ResourceGroupName
Specifies the name of the resource group to create resources.
```yaml
Type: String
```
### -SecurityType
Specifies the security type of the image to be captured.
```yaml
Type: String
```
### -StorageAccountName
Specifies the name of the storage account where assets will be downloaded from and used during the image process.
```yaml
Type: String
```
### -StorageEndpoint
Specifies the storage endpoint of the target storage account.
```yaml
Type: String
```
### -SubnetName
Specifies the subnet of the virtual network to be used during the image process.
```yaml
Type: String
```
### -TenantType
Specifies the tenant type used in the target environment.
```yaml
Type: String
AllowedValues: 'Commercial', 'DepartmentOfDefense','GovernmentCommunityCloud','GovernmentCommunityCloudHigh'
```
### -UserAssignedIdentityObjectId
Specifies the object ID of the managed identity used during deployment.
```yaml
Type: String
```
### -VirtualNetworkName
Specifies the virtual network name of the vNet used during the image process.
```yaml
Type: String
```
### -VmName
Specifies the name of the virtual machine to be captuired.
```yaml
Type: String
```
### -VmSize
Specifies the  size of the the virtual machine to be captuired.
```yaml
Type: String
```

## Adding Additional Installers

* Add additional installers by adding addtional var installers in image.bicep
* Any blob called will have to be uploaded to the storage account and container that are part of the parameter set
* Using the enabled argument will allow the installer to be modular and flexible during image creation

```bicep
var installers = [
  {
    name: 'myapp'
    blobName: 'software.exe'
    arguments: '/S'
    enabled: true
  }
]
```

## View status of runcommands during image creation
Example of how to view and troubleshoot the status of runcommands:
``` powershell
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

