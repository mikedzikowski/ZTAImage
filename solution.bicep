targetScope = 'subscription'

param actionGroupName string = ''
param automationAccountName string
param automationAccountPrivateDnsZoneResourceId string
param computeGalleryName string
param containerName string
param customizations array = []
param diskEncryptionSetResourceId string = ''
param distributionGroup string = ''
param deploymentNameSuffix string = utcNow('yyMMddHHs')
@secure()
param domainJoinPassword string = ''
param domainJoinUserPrincipalName string = ''
param domainName string = ''
param enableBuildAutomation bool
param excludeFromLatest bool = true
param hybridUseBenefit bool
param hybridWorkerName string = ''
param imageDefinitionNamePrefix string
param imageMajorVersion int
param imageMinorVersion int
param installAccess bool
param installExcel bool
param installOneDrive bool
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
param keyVaultPrivateDnsZoneResourceId string
@secure()
param localAdministratorPassword string
param localAdministratorUsername string
param location string = deployment().location
param logAnalyticsWorkspaceResourceId string = ''
param marketplaceImageOffer string = ''
param marketplaceImagePublisher string = ''
param marketplaceImageSKU string = ''
param msrdcwebrtcsvcInstaller string = ''
param officeInstaller string
param oUPath string
param replicaCount int
param resourceGroupName string
param sharedGalleryImageResourceId string = ''
@allowed([
  'AzureComputeGallery'
  'AzureMarketplace'
])
param sourceImageType string
param storageAccountResourceId string
param subnetResourceId string
param tags object = {}
param teamsInstaller string
param userAssignedIdentityName string
param vcRedistInstaller string = ''
param vDOTInstaller string = ''
param virtualMachineSize string

var imageDefinitionName = '${imageDefinitionNamePrefix}-${marketplaceImageSKU}'
var imageVirtualMachineName = take('vmimg-${uniqueString(deploymentNameSuffix)}', 15)
var managementVirtualMachineName = empty(hybridWorkerName) ? take('vmmgt-${uniqueString(deploymentNameSuffix)}', 15) : hybridWorkerName
var storageAccountName = split(storageAccountResourceId, '/')[8]
var subscriptionId = subscription().subscriptionId
var timeZones = {
  australiacentral: 'AUS Eastern Standard Time'
  australiacentral2: 'AUS Eastern Standard Time'
  australiaeast: 'AUS Eastern Standard Time'
  australiasoutheast: 'AUS Eastern Standard Time'
  brazilsouth: 'E. South America Standard Time'
  brazilsoutheast: 'E. South America Standard Time'
  canadacentral: 'Eastern Standard Time'
  canadaeast: 'Eastern Standard Time'
  centralindia: 'India Standard Time'
  centralus: 'Central Standard Time'
  chinaeast: 'China Standard Time'
  chinaeast2: 'China Standard Time'
  chinanorth: 'China Standard Time'
  chinanorth2: 'China Standard Time'
  eastasia: 'China Standard Time'
  eastus: 'Eastern Standard Time'
  eastus2: 'Eastern Standard Time'
  francecentral: 'Central Europe Standard Time'
  francesouth: 'Central Europe Standard Time'
  germanynorth: 'Central Europe Standard Time'
  germanywestcentral: 'Central Europe Standard Time'
  japaneast: 'Tokyo Standard Time'
  japanwest: 'Tokyo Standard Time'
  jioindiacentral: 'India Standard Time'
  jioindiawest: 'India Standard Time'
  koreacentral: 'Korea Standard Time'
  koreasouth: 'Korea Standard Time'
  northcentralus: 'Central Standard Time'
  northeurope: 'GMT Standard Time'
  norwayeast: 'Central Europe Standard Time'
  norwaywest: 'Central Europe Standard Time'
  southafricanorth: 'South Africa Standard Time'
  southafricawest: 'South Africa Standard Time'
  southcentralus: 'Central Standard Time'
  southeastasia: 'Singapore Standard Time'
  southindia: 'India Standard Time'
  swedencentral: 'Central Europe Standard Time'
  switzerlandnorth: 'Central Europe Standard Time'
  switzerlandwest: 'Central Europe Standard Time'
  uaecentral: 'Arabian Standard Time'
  uaenorth: 'Arabian Standard Time'
  uksouth: 'GMT Standard Time'
  ukwest: 'GMT Standard Time'
  usdodcentral: 'Central Standard Time'
  usdodeast: 'Eastern Standard Time'
  usgovarizona: 'Mountain Standard Time'
  usgovtexas: 'Central Standard Time'
  usgovvirginia: 'Eastern Standard Time'
  westcentralus: 'Mountain Standard Time'
  westeurope: 'Central Europe Standard Time'
  westindia: 'India Standard Time'
  westus: 'Pacific Standard Time'
  westus2: 'Pacific Standard Time'
  westus3: 'Mountain Standard Time'
}

module baseline 'modules/baseline.bicep' = {
  name: 'baseline-${deploymentNameSuffix}'
  params: {
    computeGalleryName: computeGalleryName
    containerName: containerName
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    enableBuildAutomation: enableBuildAutomation
    hybridUseBenefit: hybridUseBenefit
    imageDefinitionName: imageDefinitionName
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    resourceGroupName: resourceGroupName
    storageAccountResourceId: storageAccountResourceId
    subnetResourceId: subnetResourceId
    subscriptionId: subscriptionId
    tags: tags
    userAssignedIdentityName: userAssignedIdentityName
  }
}

module buildAutomation 'modules/buildAutomation.bicep' = if (enableBuildAutomation) {
  name: 'build-automation-${deploymentNameSuffix}'
  params: {
    actionGroupName: actionGroupName
    automationAccountName: automationAccountName
    automationAccountPrivateDnsZoneResourceId: automationAccountPrivateDnsZoneResourceId
    computeGalleryResourceId: baseline.outputs.computeGalleryResourceId
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    distributionGroup: distributionGroup
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    enableBuildAutomation: enableBuildAutomation
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
    imageVirtualMachineName: imageVirtualMachineName
    installAccess: installAccess
    installExcel: installExcel
    installOneDrive: installOneDrive
    installOneNote: installOneNote
    installOutlook: installOutlook
    installPowerPoint: installPowerPoint
    installProject: installProject
    installPublisher: installPublisher
    installSkypeForBusiness: installSkypeForBusiness
    installTeams: installTeams
    installVirtualDesktopOptimizationTool: installVirtualDesktopOptimizationTool
    installVisio: installVisio
    installWord: installWord
    keyVaultName: keyVaultName
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
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
    oUPath: oUPath
    replicaCount: replicaCount
    resourceGroupName: resourceGroupName
    sharedGalleryImageResourceId: sharedGalleryImageResourceId
    sourceImageType: sourceImageType
    storageAccountName: storageAccountName
    subnetResourceId: subnetResourceId
    subscriptionId: subscriptionId
    tags: tags
    teamsInstaller: teamsInstaller
    timeZone: timeZones[location]
    userAssignedIdentityClientId: baseline.outputs.userAssignedIdentityClientId
    userAssignedIdentityPrincipalId: baseline.outputs.userAssignedIdentityPrincipalId
    userAssignedIdentityResourceId: baseline.outputs.userAssignedIdentityResourceId
    vcRedistInstaller: vcRedistInstaller
    vDOTInstaller: vDOTInstaller
    virtualMachineSize: virtualMachineSize
  }
}

module imageBuild 'modules/imageBuild.bicep' = {
  name: 'image-build-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    computeGalleryName: computeGalleryName
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    enableBuildAutomation: enableBuildAutomation
    excludeFromLatest: excludeFromLatest
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
    imageVirtualMachineName: imageVirtualMachineName
    installAccess: installAccess
    installExcel: installExcel
    installOneDrive: installOneDrive
    installOneNote: installOneNote
    installOutlook: installOutlook
    installPowerPoint: installPowerPoint
    installProject: installProject
    installPublisher: installPublisher
    installSkypeForBusiness: installSkypeForBusiness
    installTeams: installTeams
    installVirtualDesktopOptimizationTool: installVirtualDesktopOptimizationTool
    installVisio: installVisio
    installWord: installWord
    keyVaultName: keyVaultName
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    managementVirtualMachineName: managementVirtualMachineName
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    replicaCount: replicaCount
    sharedGalleryImageResourceId: sharedGalleryImageResourceId
    sourceImageType: sourceImageType
    storageAccountName: storageAccountName
    subnetResourceId: subnetResourceId
    tags: tags
    teamsInstaller: teamsInstaller
    userAssignedIdentityClientId: baseline.outputs.userAssignedIdentityClientId
    userAssignedIdentityPrincipalId: baseline.outputs.userAssignedIdentityPrincipalId
    userAssignedIdentityResourceId: baseline.outputs.userAssignedIdentityResourceId
    vcRedistInstaller: vcRedistInstaller
    vDOTInstaller: vDOTInstaller
    virtualMachineSize: virtualMachineSize
  }
  dependsOn: [
    buildAutomation
  ]
}
