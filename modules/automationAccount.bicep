param automationAccountName string
param automationAccountPrivateDnsZoneResourceId string
param computeGalleryName string
param containerName string
param customizations array
param diskEncryptionSetResourceId string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableBuildAutomation bool
param imageDefinitionName string
param imageMajorVersion int
param imageMinorVersion int
param imageVirtualMachineName string
param installAccess bool
param installExcel bool
param installOneDriveForBusiness bool
param installOneNote bool
param installOutlook bool
param installPowerPoint bool
param installProject bool
param installPublisher bool
param installSkypeForBusiness bool
param installTeams bool
param installVirtualDesktopOptimizationTool bool
param installVisio bool
param installWord bool
param keyVaultName string
param jobScheduleName string = newGuid()
@secure()
param localAdministratorPassword string
param localAdministratorUsername string
param location string
param logAnalyticsWorkspaceResourceId string
param managementVirtualMachineName string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param marketplaceImageSKU string
param msrdcwebrtcsvcInstaller string
param officeInstaller string
param oUPath string
param replicaCount int
param resourceGroupName string
param sharedGalleryImageResourceId string
param sourceImageType string
param storageAccountName string
param subnetResourceId string
param tags object
param teamsInstaller string
param templateSpecResourceId string
param tenantType string
param time string = utcNow()
param timeZone string
param userAssignedIdentityClientId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param vcRedistInstaller string
param vDOTInstaller string
param virtualMachineName string
param virtualMachineSize string

var privateEndpointName = 'pe-${automationAccountName}'
var runbookName = 'Zero-Trust-Image-Build-Automation'
var subscriptionId = subscription().subscriptionId
var tenantId = subscription().tenantId

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' existing = {
  name: virtualMachineName
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' = {
  name: automationAccountName
  location: location
  tags: contains(tags, 'Microsoft.Automation/automationAccounts') ? tags['Microsoft.Automation/automationAccounts'] : {}
  properties: {
    disableLocalAuth: false
    publicNetworkAccess: false
    sku: {
      name: 'Basic'
    }
    encryption: {
      keySource: 'Microsoft.Automation'
      identity: {}
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  tags: contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        id: resourceId('Microsoft.Network/privateEndpoints/privateLinkServiceConnections', privateEndpointName, privateEndpointName)
        properties: {
          privateLinkServiceId: automationAccount.id
          groupIds: [
            'DSCAndHybridWorker'
          ]
        }
      }
    ]
    customNetworkInterfaceName: 'nic-${automationAccountName}'
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azure-automation-net'
        properties: {
          privateDnsZoneId: automationAccountPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

resource runCommand 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = {
  name: 'runbook'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  parent: virtualMachine
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'AutomationAccountName'
        value: 'aa-test-d-eu'
      }
      {
        name: 'Environment'
        value: environment().name
      }
      {
        name: 'ResourceGroupName'
        value: resourceGroup().name
      }
      {
        name: 'RunbookName'
        value: runbookName
      }
      {
        name: 'SubscriptionId'
        value: subscription().subscriptionId
      }
      {
        name: 'TenantId'
        value: tenant().tenantId
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: '6906caa8-5ebb-46f7-aff8-0f169ea4600c'
      }
    ]
    source: {
      script: '''
param (
[string]$AutomationAccountName,
[string]$Environment,
[string]$ResourceGroupName,
[string]$RunbookName,
[string]$SubscriptionId,
[string]$TenantId,
[string]$UserAssignedIdentityClientId
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

try 
{
Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity -AccountId $UserAssignedIdentityClientId | Out-Null

$Script = @'
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
  [string]$TenantType,

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
      tenantType = $TenantType
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
'@
            $Script | Out-File -FilePath '.\New-AzureZeroTrustImageBuild.ps1'
            Import-AzAutomationRunbook -Name $RunbookName -Path '.\New-AzureZeroTrustImageBuild.ps1' -Type PowerShell -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Published -Force | Out-Null
        }
        catch 
        {
            $_ | Select-Object *
            throw
        }
      '''
    }
  }
}

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2022-08-08' = {
  parent: automationAccount
  name: imageDefinitionName
  properties: {
    frequency: 'Day'
    interval: 1
    startTime: dateTimeAdd(time, 'P1D')
    timeZone: timeZone
  }
}

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = {
  parent: automationAccount
  #disable-next-line use-stable-resource-identifiers
  name: jobScheduleName
  properties: {
    parameters: {
      computeGalleryName: computeGalleryName
      containerName: containerName
      customizations: string(customizations)
      diskEncryptionSetResourceId: diskEncryptionSetResourceId
      enableBuildAutomation: string(enableBuildAutomation)
      environmentName: environment().name
      imageDefinitionName: imageDefinitionName
      imageMajorVersion: string(imageMajorVersion)
      imageMinorVersion: string(imageMinorVersion)
      imageVirtualMachineName: imageVirtualMachineName
      installAccess: string(installAccess)
      installExcel: string(installExcel)
      installOneDriveForBusiness: string(installOneDriveForBusiness)
      installOneNote: string(installOneNote)
      installOutlook: string(installOutlook)
      installPowerPoint: string(installPowerPoint)
      installProject: string(installProject)
      installPublisher: string(installPublisher)
      installSkypeForBusiness: string(installSkypeForBusiness)
      installTeams: string(installTeams)
      installVirtualDesktopOptimizationTool: string(installVirtualDesktopOptimizationTool)
      installVisio: string(installVisio)
      installWord: string(installWord)
      keyVaultName: keyVaultName
      localAdministratorPassword: localAdministratorPassword
      localAdministratorUsername: localAdministratorUsername
      location: location
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
      managementVirtualMachineName: managementVirtualMachineName
      marketplaceImageOffer: marketplaceImageOffer
      marketplaceImagePublisher: marketplaceImagePublisher
      marketplaceImageSKU: marketplaceImageSKU
      msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
      officeInstaller: officeInstaller
      replicaCount: string(replicaCount)
      resourceGroupName: resourceGroupName
      sharedGalleryImageResourceId: sharedGalleryImageResourceId
      sourceImageType: sourceImageType
      storageAccountName: storageAccountName
      subnetResourceId: subnetResourceId
      subscriptionId: subscriptionId
      tags: string(tags)
      teamsInstaller: teamsInstaller
      templateSpecResourceId: templateSpecResourceId
      tenantId: tenantId
      tenantType: tenantType
      userAssignedIdentityClient: userAssignedIdentityClientId
      userAssignedIdentityPrincipalId: userAssignedIdentityPrincipalId
      userAssignedIdentityResourceId: userAssignedIdentityResourceId
      vcRedistInstaller: vcRedistInstaller
      vDOTInstaller: vDOTInstaller
      virtualMachineSize: virtualMachineSize
    }
    runbook: {
      name: runbookName
    }
    runOn: hybridRunbookWorkerGroup.name
    schedule: {
      name: schedule.name
    }
  }
  dependsOn: [
    runCommand
  ]
}

resource diagnostics 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (!empty(logAnalyticsWorkspaceResourceId)) {
  scope: automationAccount
  name: 'diag-${automationAccount.name}'
  properties: {
    logs: [
      {
        category: 'JobLogs'
        enabled: true
      }
      {
        category: 'JobStreams'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

resource hybridRunbookWorkerGroup 'Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups@2022-08-08' = {
  parent: automationAccount
  name: 'Zero Trust Image Build Automation'
}

resource hybridRunbookWorker 'Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups/hybridRunbookWorkers@2022-08-08' = {
  parent: hybridRunbookWorkerGroup
  name: guid(hybridRunbookWorkerGroup.id)
  properties: {
    vmResourceId: virtualMachine.id
  }
}

resource extension_HybridWorker 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: virtualMachine
  name: 'HybridWorkerForWindows'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    publisher: 'Microsoft.Azure.Automation.HybridWorker'
    type: 'HybridWorkerForWindows'
    typeHandlerVersion: '1.1'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AutomationAccountURL: automationAccount.properties.automationHybridServiceUrl
    }
  }
}

resource extension_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (!empty(domainJoinUserPrincipalName) && !empty(domainName) && !empty(oUPath)) {
  parent: virtualMachine
  name: 'JsonADDomainExtension'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    forceUpdateTag: time
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainName
      User: domainJoinUserPrincipalName
      Restart: 'true'
      Options: '3'
      OUPath: oUPath
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
  dependsOn: [
    extension_HybridWorker
  ]
}

output principalId string =  automationAccount.identity.principalId
