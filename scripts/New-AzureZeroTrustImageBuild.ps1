[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	[string]$AutomationAccountName,

	[Parameter(Mandatory)]
	[string]$ContainerName,
	
	[Parameter(Mandatory)]
	[string]$Customizations,

	[Parameter(Mandatory)]
	[string]$DiskEncryptionSetResourceId,

	[Parameter(Mandatory=$false)]
	[string]$DomainName,

	[Parameter(Mandatory)]
	[string]$EnvironmentName,

	[Parameter(Mandatory)]
	[string]$GalleryName,

	[Parameter(Mandatory)]
	[string]$GalleryResourceGroupName,

	[Parameter(Mandatory)]
	[string]$HybridUseBenefit,

	[Parameter(Mandatory)]
	[string]$HybridWorkerVirtualMachineName,

	[Parameter(Mandatory)]
	[string]$ImageName,

	[Parameter(Mandatory)]
	[string]$ImageMajorVersion,

	[Parameter(Mandatory)]
	[string]$ImageMinorVersion,

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
	[string]$Location,

	[Parameter(Mandatory)]
	[string]$LogAnalyticsWorkspaceResourceId,

	[Parameter(Mandatory)]
	[string]$MarketplaceImageOffer,

	[Parameter(Mandatory)]
	[string]$MarketplaceImagePublisher,

	[Parameter(Mandatory)]
	[string]$MarketplaceImageSKU,

	[Parameter(Mandatory)]
	[string]$MsrdcwebrtcsvcInstaller,

	[Parameter(Mandatory)]
	[string]$OfficeInstaller,

	[Parameter(Mandatory)]
	[string]$OUPath,

	[Parameter(Mandatory)]
	[string]$ReplicaCount,

	[Parameter(Mandatory)]
	[string]$ResourceGroupName,

	[Parameter(Mandatory)]
	[string]$SharedGalleryImageResourceId,

    [Parameter(Mandatory=$false)]
	[string]$SourceGalleryName,

    [Parameter(Mandatory=$false)]
	[string]$SourceGalleryResourceGroupName,

    [Parameter(Mandatory=$false)]
	[string]$SourceImageDefinitionName,

	[Parameter(Mandatory)]
	[string]$SourceImageType,

	[Parameter(Mandatory)]
	[string]$StorageAccountName,

	[Parameter(Mandatory)]
	[string]$StorageAccountResourceGroupName,

	[Parameter(Mandatory)]
	[string]$SubnetName,

	[Parameter(Mandatory)]
	[string]$SubscriptionId,

	[Parameter(Mandatory)]
	[string]$Tags,

	[Parameter(Mandatory)]
	[string]$TeamsInstaller,

	[Parameter(Mandatory)]
	[string]$TemplateSpecResourceId,

	[Parameter(Mandatory)]
	[string]$TenantId,

	[Parameter(Mandatory)]
	[string]$TenantType,

	[Parameter(Mandatory)]
	[string]$UserAssignedIdentityName,

	[Parameter(Mandatory)]
	[string]$UserAssignedIdentityResourceGroupName,

	[Parameter(Mandatory)]
	[string]$VcRedistInstaller,

	[Parameter(Mandatory)]
	[string]$VDOTInstaller,

	[Parameter(Mandatory)]
	[string]$VirtualNetworkName,

	[Parameter(Mandatory)]
	[string]$VirtualNetworkResourceGroupName,

	[Parameter(Mandatory)]
	[string]$VirtualMachineSize
)

$ErrorActionPreference = 'Stop'

try 
{
    # Import Modules
    Import-Module -Name 'Az.Accounts','Az.Compute','Az.Resources'
    Write-Output "$DestinationImageDefinitionName | $DestinationImageDefinitionResourceGroupName | Imported the required modules."

    # Connect to Azure using the System Assigned Identity
    Connect-AzAccount -Environment $EnvironmentName -Subscription $SubscriptionId -Tenant $TenantId -Identity | Out-Null
    Write-Output "$DestinationImageDefinitionName | $DestinationImageDefinitionResourceGroupName | Connected to Azure."

    $CurrentImageVersionDate = (Get-AzGalleryImageVersion -ResourceGroupName $DestinationGalleryResourceGroupName -GalleryName $DestinationGalleryName -GalleryImageDefinitionName $DestinationImageDefinitionName | Where-Object {$_.ProvisioningState -eq 'Succeeded'}).PublishingProfile.PublishedDate | Sort-Object | Select-Object -Last 1
    Write-Output "$DestinationImageDefinitionName | $DestinationImageDefinitionResourceGroupName | Compute Gallery Image (Destination), Latest Version Date: $CurrentImageVersionDate."
	
    switch($SourceImageType)
    {
        'AzureComputeGallery' {
            # Get the date of the latest image definition version
            $SourceImageVersionDate = (Get-AzGalleryImageVersion -ResourceGroupName $SourceGalleryResourceGroupName -GalleryName $SourceGalleryName -GalleryImageDefinitionName $SourceImageDefinitionName | Where-Object {$_.PublishingProfile.ExcludeFromLatest -eq $false -and $_.ProvisioningState -eq 'Succeeded'}).PublishingProfile.PublishedDate | Sort-Object | Select-Object -Last 1
            Write-Output "$DestinationImageDefinitionName | $DestinationImageDefinitionResourceGroupName | Compute Gallery Image (Source), Latest Version Date: $SourceImageVersionDate."
        }
        'AzureMarketplace' {
            # Get the date of the latest marketplace image version
            $ImageVersionDateRaw = (Get-AzVMImage -Location $Location -PublisherName $ImageBuild.Source.Publisher -Offer $ImageBuild.Source.Offer -Skus $ImageBuild.Source.Sku | Sort-Object -Property 'Version' -Descending | Select-Object -First 1).Version.Split('.')[-1]
            $Year = '20' + $ImageVersionDateRaw.Substring(0,2)
            $Month = $ImageVersionDateRaw.Substring(2,2)
            $Day = $ImageVersionDateRaw.Substring(4,2)
            $SourceImageVersionDate = Get-Date -Year $Year -Month $Month -Day $Day -Hour 00 -Minute 00 -Second 00
            Write-Output "$DestinationImageDefinitionName | $DestinationImageDefinitionResourceGroupName | Marketplace Image (Source), Latest Version Date: $SourceImageVersionDate."
        }
    }

	# If the latest source image was released after the last image build then trigger a new image build
	if($CurrentImageVersionDate -gt $SourceImageVersionDate)
	{   
		Write-Output "$DestinationImageDefinitionName | $DestinationImageDefinitionResourceGroupName | Image build initiated with a new source image version."
		$TemplateParameters = @{
            automationAccountName = $AutomationAccountName
			containerName = $ContainerName
			customizations = $Customizations | ConvertFrom-Json
			diskEncryptionSetResourceId = $DiskEncryptionSetResourceId
			domainJoinPassword = $DomainJoinPassword
			domainJoinUserPrincipalName = $DomainJoinUserPrincipalName
			domainName = $DomainName
			enableBuildAutomation = $false
			excludeFromLatest = $true
			galleryName = $GalleryName
			galleryResourceGroupName = $GalleryResourceGroupName
			hybridUseBenefit = if($HybridUseBenefit -eq 'true'){$true}else{$false}
			hybridWorkerVirtualMachineName = $HybridWorkerVirtualMachineName
			imageName = $ImageName
			imageMajorVersion = if($ImageMajorVersion -eq 'true'){$true}else{$false}
			imageMinorVersion = if($ImageMinorVersion -eq 'true'){$true}else{$false}
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
			localAdministratorPassword = $LocalAdministratorPassword
			localAdministratorUsername = $LocalAdministratorUsername
			location = $Location
			logAnalyticsWorkspaceResourceId = $LogAnalyticsWorkspaceResourceId
			marketplaceImageOffer = $MarketplaceImageOffer
			marketplaceImagePublisher = $MarketplaceImagePublisher
			marketplaceImageSKU = $MarketplaceImageSKU
			msrdcwebrtcsvcInstaller = $MsrdcwebrtcsvcInstaller
			officeInstaller = $OfficeInstaller
			oUPath = $OUPath
			replicaCount = [int]$ReplicaCount
			resourceGroupName = $ResourceGroupName
			sharedGalleryImageResourceId = $SharedGalleryImageResourceId
			sourceImageType = $SourceImageType
			storageAccountName = $StorageAccountName
			storageAccountResourceGroupName = $StorageAccountResourceGroupName
			subnetName = $SubnetName
			tags = $Tags | ConvertFrom-Json
			teamsInstaller = $TeamsInstaller
			tenantType = $TenantType
			userAssignedIdentityName = $UserAssignedIdentityName
			userAssignedIdentityResourceGroupName = $UserAssignedIdentityResourceGroupName
			vcRedistInstaller = $VcRedistInstaller
			vDOTInstaller = $VDOTInstaller
			virtualNetworkName = $VirtualNetworkName
			virtualNetworkResourceGroupName = $VirtualNetworkResourceGroupName
			virtualMachineSize = $VirtualMachineSize
        }
        New-AzDeployment -Location $Location -TemplateSpecId $TemplateSpecResourceId -TemplateParameterObject $TemplateParameters
		Write-Output "$DestinationImageDefinitionName | $DestinationImageDefinitionResourceGroupName | Image build succeeded. New image version available in the destination Compute Gallery."
	}
	else 
	{
		Write-Output "$DestinationImageDefinitionName | $DestinationImageDefinitionResourceGroupName | Image build not required. The source image version is older than the latest destination image version."
	}
}
catch {
	Write-Output "$DestinationImageDefinitionName | $DestinationImageDefinitionResourceGroupName | Image build failed. Review the deployment errors in the Azure Portal and correct the issue."
	throw
}