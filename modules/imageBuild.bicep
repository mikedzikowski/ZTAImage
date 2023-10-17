targetScope = 'resourceGroup'

param computeGalleryName string
param containerName string
param customizations array = []
param deploymentNameSuffix string = utcNow('yyMMddHHs')
param diskEncryptionSetResourceId string
param enableBuildAutomation bool
param excludeFromLatest bool
param imageDefinitionName string
param imageMajorVersion int
param imageMinorVersion int
param imageVirtualMachineName string
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
param keyVaultName string = ''
@secure()
param localAdministratorPassword string = ''
@secure()
param localAdministratorUsername string = ''
param location string = resourceGroup().location
param managementVirtualMachineName string
param marketplaceImageOffer string = ''
param marketplaceImagePublisher string = ''
param marketplaceImageSKU string = ''
param msrdcwebrtcsvcInstaller string = ''
param officeInstaller string = ''
param replicaCount int
param runbookExecution bool = false
param sharedGalleryImageResourceId string = ''
param sourceImageType string
param storageAccountName string
param subnetResourceId string
param tags object = {}
param teamsInstaller string = ''
param userAssignedIdentityClientId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param vcRedistInstaller string = ''
param vDOTInstaller string = ''
param virtualMachineSize string

var autoImageVersion = '${imageMajorVersion}.${imageSuffix}.${imageMinorVersion}'
var imageSuffix = take(deploymentNameSuffix, 9)
var resourceGroupName = resourceGroup().name
var storageEndpoint = environment().suffixes.storage

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = if (runbookExecution) {
  name: keyVaultName
}

module virtualMachine 'virtualMachine.bicep' = {
  name: 'image-vm-${deploymentNameSuffix}'
  params: {
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    localAdministratorPassword: runbookExecution ? keyVault.getSecret('LocalAdministratorPassword') : localAdministratorPassword
    localAdministratorUsername: runbookExecution ? keyVault.getSecret('LocalAdministratorUsername') : localAdministratorUsername
    location: location
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    sharedGalleryImageResourceId: sharedGalleryImageResourceId
    sourceImageType: sourceImageType
    subnetResourceId: subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
    virtualMachineName: imageVirtualMachineName
    virtualMachineSize: virtualMachineSize
  }
}

module addCustomizations 'customizations.bicep' = {
  name: 'customizations-${deploymentNameSuffix}'
  params: {
    location: location
    containerName: containerName
    customizations: customizations
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
    storageAccountName: storageAccountName
    storageEndpoint: storageEndpoint
    tags: tags
    userAssignedIdentityObjectId: userAssignedIdentityPrincipalId
    virtualMachineName: virtualMachine.outputs.name
    vDotInstaller: vDOTInstaller
    officeInstaller: officeInstaller
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    teamsInstaller: teamsInstaller
    vcRedistInstaller: vcRedistInstaller
  }
}

module restartVirtualMachine 'restartVirtualMachine.bicep' = {
  name: 'restart-vm-${deploymentNameSuffix}'
  params: {
    imageVirtualMachineName: virtualMachine.outputs.name
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
    userAssignedIdentityClientId: userAssignedIdentityClientId
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    addCustomizations
  ]
}

module sysprepVirtualMachine 'sysprepVirtualMachine.bicep' = {
  name: 'sysprep-vm-${deploymentNameSuffix}'
  params: {
    location: location
    tags: tags
    virtualMachineName: virtualMachine.outputs.name
  }
  dependsOn: [
    restartVirtualMachine
  ]
}

module generalizeVirtualMachine 'generalizeVirtualMachine.bicep' = {
  name: 'generalize-vm-${deploymentNameSuffix}'
  params: {
    imageVirtualMachineName: virtualMachine.outputs.name
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
    userAssignedIdentityClientId: userAssignedIdentityClientId
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    sysprepVirtualMachine
  ]
}

module imageVersion 'imageVersion.bicep' = {
  name: 'image-version-${deploymentNameSuffix}'
  params: {
    computeGalleryName: computeGalleryName
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    excludeFromLatest: excludeFromLatest
    imageDefinitionName: imageDefinitionName
    imageVersionNumber: autoImageVersion
    imageVirtualMachineResourceId: virtualMachine.outputs.resourceId
    location: location
    replicaCount: replicaCount
    tags: tags
  }
  dependsOn: [
    generalizeVirtualMachine
  ]
}

module removeVirtualMachine 'removeVirtualMachine.bicep' = {
  name: 'remove-vm-${deploymentNameSuffix}'
  params: {
    enableBuildAutomation: enableBuildAutomation
    imageVirtualMachineName: virtualMachine.outputs.name
    location: location
    tags: tags
    userAssignedIdentityClientId: userAssignedIdentityClientId
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    imageVersion
  ]
}
