targetScope = 'subscription'

param arcGisProInstaller string = ''
param actionGroupName string = ''
param automationAccountName string
param automationAccountPrivateDnsZoneResourceId string
param computeGalleryImageResourceId string = ''
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
param excludeFromLatest bool = false
param exemptPolicyAssignmentIds array = []
param hybridUseBenefit bool
param hybridWorkerName string = ''
param imageDefinitionNamePrefix string
param imageMajorVersion int
param imageMinorVersion int
param installAccess bool
param installArcGisPro bool
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
param existingResourceGroup bool = false
param officeInstaller string = ''
param oUPath string
param replicaCount int
param resourceGroupName string
@allowed([
  'AzureComputeGallery'
  'AzureMarketplace'
])
param sourceImageType string
param storageAccountResourceId string
param subnetResourceId string
param tags object = {}
param teamsInstaller string = ''
param userAssignedIdentityName string
param vcRedistInstaller string = ''
param vDOTInstaller string = ''
param virtualMachineSize string

var imageDefinitionName = empty(computeGalleryImageResourceId) ? '${imageDefinitionNamePrefix}-${marketplaceImageSKU}' : '${imageDefinitionNamePrefix}-${split(computeGalleryImageResourceId, '/')[10]}'
var imageVirtualMachineName = take('vmimg-${uniqueString(deploymentNameSuffix)}', 15)
var managementVirtualMachineName = empty(hybridWorkerName) ? take('vmmgt-${uniqueString(deploymentNameSuffix)}', 15) : hybridWorkerName
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

resource rg 'Microsoft.Resources/resourceGroups@2019-05-01' = if (!existingResourceGroup) {
  name: resourceGroupName
  location: location
  tags: tags
}


module baseline 'modules/baseline.bicep' = {
  name: 'baseline-${deploymentNameSuffix}'
  params: {
    computeGalleryImageResourceId: computeGalleryImageResourceId
    computeGalleryName: computeGalleryName
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    enableBuildAutomation: enableBuildAutomation
    exemptPolicyAssignmentIds: exemptPolicyAssignmentIds
    imageDefinitionName: imageDefinitionName
    location: location
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    resourceGroupName: existingResourceGroup ? resourceGroupName : rg.name
    storageAccountResourceId: storageAccountResourceId
    subscriptionId: subscriptionId
    tags: tags
    userAssignedIdentityName: userAssignedIdentityName
  }
}

module buildAutomation 'modules/buildAutomation.bicep' = if (enableBuildAutomation) {
  name: 'build-automation-${deploymentNameSuffix}'
  params: {
    actionGroupName: actionGroupName
    arcGisProInstaller: arcGisProInstaller
    automationAccountName: automationAccountName
    automationAccountPrivateDnsZoneResourceId: automationAccountPrivateDnsZoneResourceId
    computeGalleryImageResourceId: computeGalleryImageResourceId
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
    excludeFromLatest: excludeFromLatest
    hybridUseBenefit: hybridUseBenefit
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
    imageVirtualMachineName: imageVirtualMachineName
    installAccess: installAccess
    installArcGisPro: installArcGisPro
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
    resourceGroupName: existingResourceGroup ? resourceGroupName : rg.name
    sourceImageType: sourceImageType
    storageAccountResourceId: storageAccountResourceId
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
  scope: resourceGroup(subscriptionId, (existingResourceGroup ? rg.name : resourceGroupName))
  params: {
    arcGisProInstaller: arcGisProInstaller
    computeGalleryImageResourceId: computeGalleryImageResourceId
    computeGalleryName: computeGalleryName
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    enableBuildAutomation: enableBuildAutomation
    excludeFromLatest: excludeFromLatest
    hybridUseBenefit: hybridUseBenefit
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
    imageVirtualMachineName: imageVirtualMachineName
    installAccess: installAccess
    installArcGisPro: installArcGisPro
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
    sourceImageType: sourceImageType
    storageAccountResourceId: storageAccountResourceId
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
