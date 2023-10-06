[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	[string]$ComputeGalleryName,

	[Parameter(Mandatory)]
	[string]$ContainerName,
	
	[Parameter(Mandatory)]
	[string]$Customizations,

	[Parameter(Mandatory)]
	[string]$DiskEncryptionSetResourceId,

	[Parameter(Mandatory)]
	[string]$EnvironmentName,

	[Parameter(Mandatory)]
	[string]$ImageDefinitionName,

	[Parameter(Mandatory)]
	[string]$ImageMajorVersion,

	[Parameter(Mandatory)]
	[string]$ImageMinorVersion,

	[Parameter(Mandatory)]
	[string]$ImageVirtualMachineName,

	[Parameter(Mandatory)]
	[string]$InstallAccess,

	[Parameter(Mandatory)]
	[string]$InstallExcel,

	[Parameter(Mandatory)]
	[string]$InstallOneDriveForBusiness,

	[Parameter(Mandatory)]
	[string]$InstallOneNote,

	[Parameter(Mandatory)]
	[string]$InstallOutlook,

	[Parameter(Mandatory)]
	[string]$InstallPowerPoint,

	[Parameter(Mandatory)]
	[string]$InstallProject,

	[Parameter(Mandatory)]
	[string]$InstallPublisher,

	[Parameter(Mandatory)]
	[string]$InstallSkypeForBusiness,

	[Parameter(Mandatory)]
	[string]$InstallTeams,

	[Parameter(Mandatory)]
	[string]$InstallVirtualDesktopOptimizationTool,

	[Parameter(Mandatory)]
	[string]$InstallVisio,

	[Parameter(Mandatory)]
	[string]$InstallWord,

	[Parameter(Mandatory)]
	[string]$KeyVaultName,

	[Parameter(Mandatory)]
	[string]$Location,

	[Parameter(Mandatory)]
	[string]$ManagementVirtualMachineName,

	[Parameter(Mandatory=$false)]
	[string]$MarketplaceImageOffer,

	[Parameter(Mandatory=$false)]
	[string]$MarketplaceImagePublisher,

	[Parameter(Mandatory=$false)]
	[string]$MarketplaceImageSKU,

	[Parameter(Mandatory=$false)]
	[string]$MsrdcwebrtcsvcInstaller,

	[Parameter(Mandatory=$false)]
	[string]$OfficeInstaller,

	[Parameter(Mandatory)]
	[string]$ReplicaCount,

	[Parameter(Mandatory)]
	[string]$ResourceGroupName,

	[Parameter(Mandatory=$false)]
	[string]$SharedGalleryImageResourceId,

	[Parameter(Mandatory)]
	[string]$SourceImageType,

	[Parameter(Mandatory)]
	[string]$StorageAccountName,

	[Parameter(Mandatory)]
	[string]$SubnetResourceId,

	[Parameter(Mandatory)]
	[string]$SubscriptionId,

	[Parameter(Mandatory)]
	[string]$Tags,

	[Parameter(Mandatory=$false)]
	[string]$TeamsInstaller,

	[Parameter(Mandatory)]
	[string]$TemplateSpecResourceId,

	[Parameter(Mandatory)]
	[string]$TenantId,

	[Parameter(Mandatory)]
	[string]$UserAssignedIdentityClientId,

	[Parameter(Mandatory)]
	[string]$UserAssignedIdentityPrincipalId,

	[Parameter(Mandatory)]
	[string]$UserAssignedIdentityResourceId,

	[Parameter(Mandatory=$false)]
	[string]$VcRedistInstaller,

	[Parameter(Mandatory=$false)]
	[string]$VDOTInstaller,

	[Parameter(Mandatory)]
	[string]$VirtualMachineSize
)

$ErrorActionPreference = 'Stop'

try 
{
	# Set Variables
	if($SharedGalleryImageResourceId)
	{
		$SourceGalleryName = $SharedGalleryImageResourceId.Split('/')[8]
		$SourceGalleryResourceGroupName = $SharedGalleryImageResourceId.Split('/')[4]
		$SourceImageDefinitionName = $SharedGalleryImageResourceId.Split('/')[10]
	}
	$DestinationGalleryName = $GalleryName
	$DestinationGalleryResourceGroupName = $GalleryResourceGroupName
	$DestinationImageDefinitionName = $ImageDefinitionName

    # Import Modules
    Import-Module -Name 'Az.Accounts','Az.Compute','Az.Resources'
    Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Imported the required modules."

    # Connect to Azure using the System Assigned Identity
    Connect-AzAccount -Environment $EnvironmentName -Subscription $SubscriptionId -Tenant $TenantId -Identity | Out-Null
    Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Connected to Azure."

    $CurrentImageVersionDate = (Get-AzGalleryImageVersion -ResourceGroupName $DestinationGalleryResourceGroupName -GalleryName $DestinationGalleryName -GalleryImageDefinitionName $DestinationImageDefinitionName | Where-Object {$_.ProvisioningState -eq 'Succeeded'}).PublishingProfile.PublishedDate | Sort-Object | Select-Object -Last 1
    Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Compute Gallery Image (Destination), Latest Version Date: $CurrentImageVersionDate."
	
    switch($SourceImageType)
    {
        'AzureComputeGallery' {
            # Get the date of the latest image definition version
            $SourceImageVersionDate = (Get-AzGalleryImageVersion -ResourceGroupName $SourceGalleryResourceGroupName -GalleryName $SourceGalleryName -GalleryImageDefinitionName $SourceImageDefinitionName | Where-Object {$_.PublishingProfile.ExcludeFromLatest -eq $false -and $_.ProvisioningState -eq 'Succeeded'}).PublishingProfile.PublishedDate | Sort-Object | Select-Object -Last 1
            Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Compute Gallery Image (Source), Latest Version Date: $SourceImageVersionDate."
        }
        'AzureMarketplace' {
            # Get the date of the latest marketplace image version
            $ImageVersionDateRaw = (Get-AzVMImage -Location $Location -PublisherName $ImageBuild.Source.Publisher -Offer $ImageBuild.Source.Offer -Skus $ImageBuild.Source.Sku | Sort-Object -Property 'Version' -Descending | Select-Object -First 1).Version.Split('.')[-1]
            $Year = '20' + $ImageVersionDateRaw.Substring(0,2)
            $Month = $ImageVersionDateRaw.Substring(2,2)
            $Day = $ImageVersionDateRaw.Substring(4,2)
            $SourceImageVersionDate = Get-Date -Year $Year -Month $Month -Day $Day -Hour 00 -Minute 00 -Second 00
            Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Marketplace Image (Source), Latest Version Date: $SourceImageVersionDate."
        }
    }

	# If the latest source image was released after the last image build then trigger a new image build
	if($CurrentImageVersionDate -gt $SourceImageVersionDate)
	{   
		Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build initiated with a new source image version."
		$TemplateParameters = @{
			computeGalleryName = $ComputeGalleryName
			containerName = $ContainerName
			customizations = $Customizations | ConvertFrom-Json
			diskEncryptionSetResourceId = $DiskEncryptionSetResourceId
			excludeFromLatest = $true
			imageDefinitionName = $ImageDefinitionName
			imageMajorVersion = if($ImageMajorVersion -eq 'true'){$true}else{$false}
			imageMinorVersion = if($ImageMinorVersion -eq 'true'){$true}else{$false}
			imageVirtualMachineName = $ImageVirtualMachineName
			installAccess = if($InstallAccess -eq 'true'){$true}else{$false}
			installExcel = if($InstallExcel -eq 'true'){$true}else{$false}
			installOneDriveForBusiness = if($InstallOneDriveForBusiness -eq 'true'){$true}else{$false}
			installOneNote = if($InstallOneNote -eq 'true'){$true}else{$false}
			installOutlook = if($InstallOutlook -eq 'true'){$true}else{$false}
			installPowerPoint = if($InstallPowerPoint -eq 'true'){$true}else{$false}
			installProject = if($InstallProject -eq 'true'){$true}else{$false}
			installPublisher = if($InstallPublisher -eq 'true'){$true}else{$false}
			installSkypeForBusiness = if($InstallSkypeForBusiness -eq 'true'){$true}else{$false}
			installTeams = if($InstallTeams -eq 'true'){$true}else{$false}
			installVirtualDesktopOptimizationTool = if($InstallVirtualDesktopOptimizationTool -eq 'true'){$true}else{$false}
			installVisio = if($InstallVisio -eq 'true'){$true}else{$false}
			installWord = if($InstallWord -eq 'true'){$true}else{$false}
			keyVaultName = $KeyVaultName
			managementVirtualMachineName = $ManagementVirtualMachineName
			marketplaceImageOffer = $MarketplaceImageOffer
			marketplaceImagePublisher = $MarketplaceImagePublisher
			marketplaceImageSKU = $MarketplaceImageSKU
			msrdcwebrtcsvcInstaller = $MsrdcwebrtcsvcInstaller
			officeInstaller = $OfficeInstaller
			replicaCount = [int]$ReplicaCount
			resourceGroupName = $ResourceGroupName
			runbookExecution = $true
			sharedGalleryImageResourceId = $SharedGalleryImageResourceId
			sourceImageType = $SourceImageType
			storageAccountName = $StorageAccountName
			subnetResourceId = $SubnetResourceId
			tags = $Tags | ConvertFrom-Json
			teamsInstaller = $TeamsInstaller
			userAssignedIdentityClientId = $UserAssignedIdentityClientId
			userAssignedIdentityPrincipalId = $UserAssignedIdentityPrincipalId
			userAssignedIdentityResourceId = $UserAssignedIdentityResourceId
			vcRedistInstaller = $VcRedistInstaller
			vDOTInstaller = $VDOTInstaller
			virtualMachineSize = $VirtualMachineSize
        }
        New-AzDeployment -Location $Location -TemplateSpecId $TemplateSpecResourceId -TemplateParameterObject $TemplateParameters
		Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build succeeded. New image version available in the destination Compute Gallery."
	}
	else 
	{
		Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build not required. The source image version is older than the latest destination image version."
	}
}
catch 
{
	Write-Output "$DestinationImageDefinitionName | $DestinationGalleryResourceGroupName | Image build failed. Review the deployment errors in the Azure Portal and correct the issue."
	Write-Output $Error[0].Exception
	throw
}