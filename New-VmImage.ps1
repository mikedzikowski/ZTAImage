[CmdletBinding()]
param (
   [parameter(mandatory = $true)]
   $VmName,
   [parameter(mandatory = $true)]
   $ResourceGroupName,
   [parameter(mandatory = $true)]
   $GalleryName,
   [parameter(mandatory = $true)]
   $ImageName,
   [parameter(mandatory = $true)]
   $ImageVersion,
   [parameter(mandatory = $true)]
   $ImagePublisher,
   [parameter(mandatory = $true)]
   $ImageOffer,
   [parameter(mandatory = $true)]
   $ImageSku,
   [parameter(mandatory = $false)]
   [ValidateSet('Standard_LRS', 'Standard_ZRS','Premium_LRS')]
   $StorageAccountType = 'Standard_LRS',
   [parameter(mandatory = $false)]
   $PublishingProfileEndOfLifeDate = '2030-12-01',
   [parameter(mandatory = $false)]
   $HyperVGeneration = 'V2',
   [parameter(mandatory = $true)]
   $Location,
   [parameter(mandatory = $true)]
   $AdminUserName,
   [parameter(mandatory = $true)]
   $OSVersion,
   [parameter(mandatory = $true)]
   $VmSize,
   [parameter(mandatory = $true)]
   $SecurityType,
   [parameter(mandatory = $true)]
   $MiName,
   [parameter(mandatory = $true)]
   $VirtualNetworkName,
   [parameter(mandatory = $true)]
   $SubnetName,
   [parameter(mandatory = $true)]
   $ContainerName,
   [parameter(mandatory = $true)]
   [bool]$InstallAccess,
   [parameter(mandatory = $true)]
   [bool]$InstallExcel,
   [parameter(mandatory = $true)]
   [bool]$InstallFsLogix,
   [parameter(mandatory = $true)]
   [bool]$InstallOneDriveForBusiness,
   [parameter(mandatory = $true)]
   [bool]$InstallOneNote,
   [parameter(mandatory = $true)]
   [bool]$InstallOutlook,
   [parameter(mandatory = $true)]
   [bool]$InstallPowerPoint,
   [parameter(mandatory = $true)]
   [bool]$InstallProject,
   [parameter(mandatory = $true)]
   [bool]$InstallPublisher,
   [parameter(mandatory = $true)]
   [bool]$InstallSkypeForBusiness,
   [parameter(mandatory = $true)]
   [bool]$InstallTeams,
   [parameter(mandatory = $true)]
   [bool]$InstallVirtualDesktopOptimizationTool,
   [parameter(mandatory = $true)]
   [bool]$InstallVisio,
   [parameter(mandatory = $true)]
   [bool]$InstallWord,
   [parameter(mandatory = $true)]
   $StorageAccountName,
   [parameter(mandatory = $true)]
   [ValidateSet('Commercial', 'DepartmentOfDefense','GovernmentCommunityCloud','GovernmentCommunityCloudHigh')]
   $TenantType,
   [parameter(mandatory = $true)]
   $UserAssignedIdentityObjectId
)

# Random Password for Image VM
[string]$password = [System.Web.Security.Membership]::GeneratePassword(123,5)
[Security.SecureString]$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

# Storage Endpoint
$Environment = (Get-AzContext).Environment.Name
$StorageEndpointSuffix = (Get-AzEnvironment -Name $Environment).StorageEndpointSuffix
$StorageEndpoint = '.blob.' + $StorageEndpointSuffix

try {
   Write-Host "Checking for Virtual Machine..." -ForegroundColor White
   $sourceVm = Get-AzVM -Name $VmName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue

   If ($sourceVm) {
      # Customize Virtual Machine and Sysprep
      Write-host "Image Virtual Machine Found. Customizing by deploying image.Bicep." -ForegroundColor Yellow
      $imageArgs = @{
         containerName = $ContainerName
         installAccess = $InstallAccess
         installExcel = $InstallExcel
         installFsLogix = $installFsLogix
         installOneDriveForBusiness = $InstallOneDriveForBusiness
         installOneNote = $InstallOneNote
         installOutlook = $InstallOutlook
         installPowerPoint = $InstallPowerPoint
         installProject = $InstallProject
         installPublisher = $InstallPublisher
         installSkypeForBusiness = $InstallSkypeForBusiness
         installTeams = $InstallTeams
         installVirtualDesktopOptimizationTool = $InstallVirtualDesktopOptimizationTool
         installVisio = $InstallVisio
         installWord = $InstallWord
         storageAccountName = $StorageAccountName
         storageEndpoint = $StorageEndpoint
         TenantType = $TenantType
         userAssignedIdentityObjectId = $UserAssignedIdentityObjectId
         ResourceGroupName = $ResourceGroupName
         VmName = $VmName
      }
      New-AzResourceGroupDeployment -Name customize -TemplateFile .\modules\image.bicep @imageArgs -Verbose
      
      Start-Sleep -Seconds 60

      # Mark VM as Generalized - currently only supported with PowerShell
      Write-host "Marking VM as generalized..." -ForegroundColor White
      $generalize = Set-AzVm -ResourceGroupName $sourceVm.ResourceGroupName -Name $sourceVM.Name -Generalized

      # Sleeping to ensure generalization completes
      Start-Sleep -Seconds 30
   }
   if (!$sourceVm) {
      # Build VM if source VM is not found
      Write-host "Image Virtual Machine was not found. Creating Image VM by deploying generalizedVM.Bicep." -ForegroundColor Yellow
      $vmDeploymentArguments = @{
         AdminUsername = $AdminUserName
         AdminPassword = $securePassword
         MiName = $MiName
         OSVersion = $OSVersion
         ResourceGroupName = $ResourceGroupName
         SecurityType = $SecurityType
         SubnetName = $SubnetName
         VirtualNetworkName = $VirtualNetworkName
         VmName = $VmName
         VmSize = $VmSize
      }
      New-AzResourceGroupDeployment -Name ImageVm -TemplateFile .\modules\generalizedVM.bicep @vmDeploymentArguments -Verbose

      Start-Sleep -Seconds 30

      # Sleeping to ensure deployment completes
      Start-Sleep -Seconds 30
      # Create Source VM object
      $sourceVM = Get-AzVM -Name $VmName -ResourceGroupName $ResourceGroupName

      Start-Sleep -Seconds 120

      # Customize Virtual Machine and Sysprep
      Write-host "Customizing by deploying image.bicep." -ForegroundColor White
      $imageArgs = @{
         containerName = $ContainerName
         installAccess = $InstallAccess
         installExcel = $InstallExcel
         installFsLogix = $installFsLogix
         installOneDriveForBusiness = $InstallOneDriveForBusiness
         installOneNote = $InstallOneNote
         installOutlook = $InstallOutlook
         installPowerPoint = $InstallPowerPoint
         installProject = $InstallProject
         installPublisher = $InstallPublisher
         installSkypeForBusiness = $InstallSkypeForBusiness
         installTeams = $InstallTeams
         installVirtualDesktopOptimizationTool = $InstallVirtualDesktopOptimizationTool
         installVisio = $InstallVisio
         installWord = $InstallWord
         storageAccountName = $StorageAccountName
         storageEndpoint = $StorageEndpoint
         TenantType = $TenantType
         userAssignedIdentityObjectId = $UserAssignedIdentityObjectId
         ResourceGroupName = $ResourceGroupName
         VmName = $VmName
      }
      New-AzResourceGroupDeployment -Name customize -TemplateFile .\modules\image.bicep @imageArgs -Verbose

      Start-Sleep -Seconds 60

      # Mark VM as Generalized
      Write-host "Marking VM as generalized..." -ForegroundColor White
      $generalize = Set-AzVm -ResourceGroupName $sourceVm.ResourceGroupName -Name $sourceVM.Name -Generalized

      # Sleeping to ensure generalization completes
      Start-Sleep -Seconds 30
   }
   if ($generalize) {
      Write-host "VM marked as generalized..." -ForegroundColor White
      $gallery = Get-AzGallery -GalleryName $GalleryName -ResourceGroupName $ResourceGroupName

      # Set Features Available with Image and Zero Trust
      $IsHibernateSupported = @{Name = 'IsHibernateSupported'; Value = 'True' }
      $IsAcceleratedNetworkSupported = @{Name = 'IsAcceleratedNetworkSupported'; Value = 'True' }
      $ConfidentialVMSupported = @{Name = 'SecurityType'; Value = 'TrustedLaunch' }
      $features = @($IsHibernateSupported, $IsAcceleratedNetworkSupported, $ConfidentialVMSupported)

      # Create New Gallery Image
      Write-host "Creating New Gallery Image Definition..." -ForegroundColor White
      $galleryImage = New-AzGalleryImageDefinition `
         -GalleryName $gallery.Name `
         -Feature $features `
         -ResourceGroupName $gallery.ResourceGroupName `
         -Location $gallery.Location `
         -Name $imageName `
         -OsState Generalized `
         -OsType Windows `
         -Publisher $imagePublisher `
         -Offer $imageOffer `
         -Sku $imageSku `
         -HyperVGeneration $HyperVGeneration

      # Set Target Regions for Replication
      $region1 = @{Name = $Location; ReplicaCount = 1 }
      $targetRegions = @($region1)

      # Create New Gallery Image Version
      Write-host "Creating New Gallery Image Version..." -ForegroundColor White
      $newImage = New-AzGalleryImageVersion `
         -GalleryImageDefinitionName $galleryImage.Name `
         -GalleryImageVersionName $imageVersion `
         -GalleryName $gallery.Name `
         -ResourceGroupName $gallery.ResourceGroupName `
         -Location $Location `
         -TargetRegion $targetRegions `
         -Source $sourceVM.Id.ToString() `
         -PublishingProfileEndOfLifeDate $PublishingProfileEndOfLifeDate `
         -StorageAccountType $StorageAccountType

      Write-host "Virtual Machine Image" $($galleryImage.name) "version $($newImage.name) has been created!" -ForegroundColor White
   }
   # Removing Image Virtual Machine
   Write-host "Removing Image Virtual Machine $($Sourcevm.name)..." -ForegroundColor White
   Remove-AzVm -ResourceGroupName $sourceVM.ResourceGroupName -Name $sourceVM.name -ForceDeletion $true -Force -Verbose

   # Removing Image Virtual Machine NSG
   Write-host "Removing Image Virtual Machine NSG associated with $($Sourcevm.name)..." -ForegroundColor White
   Remove-AzNetworkSecurityGroup -Name "nsg-image-vm" -ResourceGroupName $sourceVM.ResourceGroupName -Force
}
catch {
   Write-Host $_.error
}
