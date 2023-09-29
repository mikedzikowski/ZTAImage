targetScope = 'subscription'

param containerName string
param customizations array
param diskEncryptionSetResourceId string
param deploymentNameSuffix string
param enableBuildAutomation bool
param excludeFromLatest bool
param galleryName string
param galleryResourceGroupName string
param hybridUseBenefit bool
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
@secure()
param localAdministratorPassword string
@secure()
param localAdministratorUsername string
param location string
param managementVirtualMachineName string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param marketplaceImageSKU string
param msrdcwebrtcsvcInstaller string
param officeInstaller string
param replicaCount int
param resourceGroupName string
param sourceImageType string
param storageAccountName string
param storageAccountResourceGroupName string
param subnetName string
param subscriptionId string
param tags object
param teamsInstaller string
param tenantType string
param userAssignedIdentityName string
param userAssignedIdentityResourceGroupName string
param vcRedistInstaller string
param vDOTInstaller string
param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualMachineSize string

var autoImageVersion = '${imageMajorVersion}.${imageSuffix}.${imageMinorVersion}'
var cloud = environment().name
var imageSuffix = take(deploymentNameSuffix, 9)

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: keyVaultName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  scope: resourceGroup(subscriptionId, storageAccountResourceGroupName)
  name: storageAccountName
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(subscriptionId, userAssignedIdentityResourceGroupName)
  name: userAssignedIdentityName
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  scope: resourceGroup(subscriptionId, virtualNetworkResourceGroupName)
  name: virtualNetworkName
}

resource gallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  scope: resourceGroup(subscriptionId, galleryResourceGroupName)
  name: galleryName
}

module generalizedVM 'generalizedVM.bicep' = {
  name: 'image-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    localAdministratorPassword: enableBuildAutomation ? keyVault.getSecret('LocalAdministratorPassword') : localAdministratorPassword
    localAdministratorUsername: enableBuildAutomation ? keyVault.getSecret('LocalAdministratorUsername') : localAdministratorUsername
    location: location
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    subnetName: subnetName
    tags: tags
    userAssignedIdentityName: userAssignedIdentity.name
    userAssignedIdentityResourceGroupName: userAssignedIdentityResourceGroupName
    virtualMachineName: imageVirtualMachineName
    virtualMachineSize: virtualMachineSize
    virtualNetworkName: virtualNetwork.name
    virtualNetworkResourceGroupName: split(virtualNetwork.id, '/')[4]
  }
}

module imageCustomizations 'customizations.bicep' = {
  name: 'custom-vm-${deploymentNameSuffix}'
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
    storageAccountName: storageAccount.name
    storageEndpoint: storageAccount.properties.primaryEndpoints.blob
    tags: tags
    tenantType: tenantType
    userAssignedIdentityObjectId: userAssignedIdentity.properties.principalId
    vmName: imageVirtualMachineName
    vDotInstaller: vDOTInstaller
    officeInstaller: officeInstaller
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    teamsInstaller: teamsInstaller
    vcRedistInstaller: vcRedistInstaller
  }
  dependsOn: [
    generalizedVM
  ]
}

module managementVm 'managementVM.bicep' = {
  name: 'management-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    containerName: containerName
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    hybridUseBenefit: hybridUseBenefit
    localAdministratorPassword: enableBuildAutomation ? keyVault.getSecret('LocalAdministratorPassword') : localAdministratorPassword
    localAdministratorUsername: enableBuildAutomation ? keyVault.getSecret('LocalAdministratorUsername') : localAdministratorUsername
    location: location
    storageEndpoint: storageAccount.properties.primaryEndpoints.blob
    subnetName: subnetName
    tags: tags
    userAssignedIdentityName: userAssignedIdentity.name
    userAssignedIdentityResourceGroupName: userAssignedIdentityResourceGroupName
    virtualMachineName: managementVirtualMachineName
    virtualMachineSize: virtualMachineSize
    virtualNetworkName: virtualNetwork.name
    virtualNetworkResourceGroup: split(virtualNetwork.id, '/')[4]
  }
  dependsOn: [
    gallery
    generalizedVM
    imageCustomizations
    userAssignedIdentity
  ]
}

module restartVM 'restartVM.bicep' = {
  name: 'restart-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    cloud: cloud
    imageVirtualMachineName: generalizedVM.outputs.Name
    resourceGroupName: generalizedVM.outputs.ResourceGroupName
    location: location
    tags: tags
    userAssignedIdentityName: userAssignedIdentity.name
    userAssignedIdentityResourceGroupName: userAssignedIdentityResourceGroupName
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    imageCustomizations
    managementVm
  ]
}

module sysprep 'sysprep.bicep' = {
  name: 'sysprep-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    containerName: containerName
    location: location
    storageAccountName: storageAccountName
    storageEndpoint: storageAccount.properties.primaryEndpoints.blob
    tags: tags
    userAssignedIdentityObjectId: userAssignedIdentity.properties.principalId
    virtualMachineName: generalizedVM.outputs.Name
  }
  dependsOn: [
    imageCustomizations
    managementVm
    restartVM
  ]
}

module generalizeVm 'runGeneralization.bicep' = {
  name: 'generalize-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    cloud: cloud
    imageVirtualMachineName: generalizedVM.outputs.Name
    resourceGroupName: generalizedVM.outputs.ResourceGroupName
    location: location
    userAssignedIdentityName: userAssignedIdentity.name
    userAssignedIdentityResourceGroupName: userAssignedIdentityResourceGroupName
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    imageCustomizations
    managementVm
    restartVM
    sysprep
  ]
}

module image 'gallery.bicep' = {
  name: 'gallery-image-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, galleryResourceGroupName)
  params: {
    excludeFromLatest: excludeFromLatest
    galleryName: gallery.name
    imageDefinitionName: imageDefinitionName
    imageVersionNumber: autoImageVersion
    imageVirtualMachineResourceId: generalizedVM.outputs.ResourceId
    location: location
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    replicaCount: replicaCount
  }
  dependsOn: [
    imageCustomizations
    managementVm
    restartVM
    sysprep
  ]
}

module remove 'removeVM.bicep' = {
  name: 'remove-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    cloud: cloud
    imageVirtualMachineName: generalizedVM.outputs.Name
    resourceGroupName: generalizedVM.outputs.ResourceGroupName
    location: location
    userAssignedIdentityName: userAssignedIdentity.name
    userAssignedIdentityResourceGroupName: userAssignedIdentityResourceGroupName
    virtualMachineName: managementVirtualMachineName
  }
  dependsOn: [
    gallery
    generalizeVm
    image
    imageCustomizations
    managementVm
    sysprep
  ]
}
