targetScope = 'subscription'

param computeGalleryName string
param containerName string
param customizations array
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
param keyVaultName string = ''
@secure()
param localAdministratorPassword string = ''
@secure()
param localAdministratorUsername string = ''
param location string = deployment().location
param managementVirtualMachineName string
param marketplaceImageOffer string = ''
param marketplaceImagePublisher string = ''
param marketplaceImageSKU string = ''
param msrdcwebrtcsvcInstaller string = ''
param officeInstaller string = ''
param replicaCount int
param resourceGroupName string
param runbookExecution bool = false
param sharedGalleryImageResourceId string = ''
param sourceImageType string
param storageAccountName string
param subnetResourceId string
param subscriptionId string = subscription().subscriptionId
param tags object
param teamsInstaller string = ''
param userAssignedIdentityClientId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param vcRedistInstaller string
param vDOTInstaller string = ''
param virtualMachineSize string

var autoImageVersion = '${imageMajorVersion}.${imageSuffix}.${imageMinorVersion}'
var imageSuffix = take(deploymentNameSuffix, 9)
var storageEndpoint = environment().suffixes.storage

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = if (runbookExecution) {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: keyVaultName
}

module virtualMachine 'virtualMachine.bicep' = {
  name: 'image-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
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
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    containerName: containerName
    customizations: customizations
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
    storageAccountName: storageAccountName
    storageEndpoint: storageEndpoint
    tags: tags
    userAssignedIdentityObjectId: userAssignedIdentityPrincipalId
    vmName: virtualMachine.outputs.name
    vDotInstaller: vDOTInstaller
    officeInstaller: officeInstaller
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    teamsInstaller: teamsInstaller
    vcRedistInstaller: vcRedistInstaller
  }
}

module restart 'restart.bicep' = {
  name: 'restart-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
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

module sysprep 'sysprep.bicep' = {
  name: 'sysprep-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    containerName: containerName
    location: location
    storageAccountName: storageAccountName
    storageEndpoint: storageEndpoint
    tags: tags
    userAssignedIdentityObjectId: userAssignedIdentityPrincipalId
    virtualMachineName: virtualMachine.outputs.name
  }
  dependsOn: [
    restart
  ]
}

module generalize 'generalize.bicep' = {
  name: 'generalize-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    imageVirtualMachineName: virtualMachine.outputs.name
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
    userAssignedIdentityClientId: userAssignedIdentityClientId
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    sysprep
  ]
}

module imageVersion 'imageVersion.bicep' = {
  name: 'image-version-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
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
    generalize
  ]
}

module remove 'removeVM.bicep' = {
  name: 'remove-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    enableBuildAutomation: enableBuildAutomation
    imageVirtualMachineName: virtualMachine.outputs.name
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
    userAssignedIdentityClientId: userAssignedIdentityClientId
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    generalize
  ]
}
