targetScope = 'subscription'

param automationAccountName string
param containerName string
param customizations array = []
param diskEncryptionSetResourceId string
param deploymentNameSuffix string = utcNow('yyMMddHHs')
@secure()
param domainJoinPassword string = ''
param domainJoinUserPrincipalName string = ''
param domainName string = ''
param enableBuildAutomation bool
param excludeFromLatest bool
param galleryName string
param galleryResourceGroupName string
param hybridUseBenefit bool
param imageDefinitionNamePrefix string
param imageMajorVersion int
param imageMinorVersion int
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
@secure()
param localAdministratorPassword string
param localAdministratorUsername string
param location string = deployment().location
param logAnalyticsWorkspaceResourceId string = ''
param marketplaceImageOffer string = ''
param marketplaceImagePublisher string = ''
param marketplaceImageSKU string = ''
param msrdcwebrtcsvcInstaller string
param officeInstaller string
param oUPath string
param replicaCount int
param resourceGroupName string
param securityPrincipalObjectIds array
@allowed([
  'AzureComputeGallery'
  'AzureMarketplace'
])
param sourceImageType string
param storageAccountName string
param storageAccountResourceGroupName string
param subnetName string
param tags object
param teamsInstaller string
@allowed([
  'Commercial'
  'DepartmentOfDefense'
  'GovernmentCommunityCloud'
  'GovernmentCommunityCloudHigh'
])
param tenantType string
param userAssignedIdentityName string
param userAssignedIdentityResourceGroupName string
param vcRedistInstaller string
param vDOTInstaller string
param virtualMachineSize string
param virtualNetworkName string
param virtualNetworkResourceGroupName string

var hybridWorkerVirtualMachineName = take('vmhw-${uniqueString(deploymentNameSuffix)}', 15)
var imageDefinitionName = '${imageDefinitionNamePrefix}-${marketplaceImageSKU}'
var imageVirtualMachineName = take('vmimg-${uniqueString(deploymentNameSuffix)}', 15)
var managementVirtualMachineName = take('vmmgt-${uniqueString(deploymentNameSuffix)}', 15)
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

module buildAutomation 'modules/buildAutomation.bicep' = if (enableBuildAutomation) {
  name: 'build-automation-${deploymentNameSuffix}'
  params: {
    automationAccountName: automationAccountName
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    galleryName: galleryName
    galleryResourceGroupName: galleryResourceGroupName
    hybridUseBenefit: hybridUseBenefit
    hybridWorkerVirtualMachineName: hybridWorkerVirtualMachineName
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
    installAccess: installAccess
    installExcel: installExcel
    installOneDriveForBusiness: installOneDriveForBusiness
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
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    oUPath: oUPath
    replicaCount: replicaCount
    resourceGroupName: resourceGroupName
    securityPrincipalObjectIds: securityPrincipalObjectIds
    sourceImageType: sourceImageType
    storageAccountName: storageAccountName
    storageAccountResourceGroupName: storageAccountResourceGroupName
    subnetName: subnetName
    subscriptionId: subscriptionId
    tags: tags
    teamsInstaller: teamsInstaller
    tenantType: tenantType
    timeZone: timeZones[location]
    userAssignedIdentityName: userAssignedIdentityName
    userAssignedIdentityResourceGroupName: userAssignedIdentityResourceGroupName
    vcRedistInstaller: vcRedistInstaller
    vDOTInstaller: vDOTInstaller
    virtualMachineName: hybridWorkerVirtualMachineName
    virtualMachineSize: virtualMachineSize
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
  }
}

module imageBuild 'modules/imageBuild.bicep' = {
  name: 'image-build-${deploymentNameSuffix}'
  params: {
    containerName: containerName
    customizations: customizations
    deploymentNameSuffix: deploymentNameSuffix
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    enableBuildAutomation: enableBuildAutomation
    excludeFromLatest: excludeFromLatest
    galleryName: galleryName
    galleryResourceGroupName: galleryResourceGroupName
    hybridUseBenefit: hybridUseBenefit
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
    imageVirtualMachineName: imageVirtualMachineName
    installAccess: installAccess
    installExcel: installExcel
    installOneDriveForBusiness: installOneDriveForBusiness
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
    resourceGroupName: resourceGroupName
    sourceImageType: sourceImageType
    storageAccountName: storageAccountName
    storageAccountResourceGroupName: storageAccountResourceGroupName
    subnetName: subnetName
    subscriptionId: subscriptionId
    tags: tags
    teamsInstaller: teamsInstaller
    tenantType: tenantType
    userAssignedIdentityName: userAssignedIdentityName
    userAssignedIdentityResourceGroupName: userAssignedIdentityResourceGroupName
    vcRedistInstaller: vcRedistInstaller
    vDOTInstaller: vDOTInstaller
    virtualMachineSize: virtualMachineSize
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
  }
}
