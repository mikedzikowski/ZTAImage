targetScope = 'subscription'

param containerName string
param deploymentNameSuffix string = utcNow()
param excludeFromLatest bool
param galleryName string
param galleryResourceGroup string
param guidValue string = newGuid()
param imageName string
param imageVersion string
param imageVmRg string
param installAccess bool
param installExcel bool
param installFsLogix bool
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
param location string = deployment().location
param managementVmRg string
param miName string
param miResourceGroup string
param offer string
param OsVersion string
param publisher string
param replicaCount int = 1
param saResourceGroup string
param sku string
param storageAccountName string
param subnetName string
@allowed([
  'Commercial'
  'DepartmentOfDefense'
  'GovernmentCommunityCloud'
  'GovernmentCommunityCloudHigh'
])
param TenantType string
param virtualNetworkName string
param virtualNetworkResourceGroup string
param vmSize string
param customizations array = []
param vDotInstaller string

var cloud = environment().name
var adminPw = '${toUpper(uniqueString(subscription().id))}-${guidValue}'
var adminUsername = 'xadmin'
var subscriptionId = subscription().subscriptionId
var securityType = 'TrustedLaunch'
var imageVmName = 'vm-image'
var managementVmName = 'vm-management'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  scope: resourceGroup(subscriptionId, saResourceGroup)
  name: storageAccountName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(subscriptionId, miResourceGroup)
  name: miName
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  scope: resourceGroup(subscriptionId, virtualNetworkResourceGroup)
  name: virtualNetworkName
}

resource gallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  scope: resourceGroup(subscriptionId, galleryResourceGroup)
  name: galleryName
}

module imageVm 'modules/generalizedVM.bicep' = {
  name: 'image-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, imageVmRg)
  params: {
    location: location
    adminPassword: adminPw
    adminUsername: adminUsername
    miName: managedIdentity.name
    miResourceGroup: miResourceGroup
    OSVersion: OsVersion
    securityType: securityType
    subnetName: subnetName
    virtualNetworkName: virtualNetwork.name
    virtualResourceGroup: split(virtualNetwork.id, '/')[4]
    vmName: imageVmName
    vmSize: vmSize
  }
}

module customize 'modules/image.bicep' = {
  name: 'custom-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, imageVmRg)
  params: {
    location: location
    containerName: containerName
    customizations: customizations
    installAccess:  installAccess
    installExcel: installExcel
    installFsLogix: installFsLogix
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
    TenantType: TenantType
    userAssignedIdentityObjectId: managedIdentity.properties.principalId
    vmName: imageVmName
    vDotInstaller: vDotInstaller
  }
  dependsOn: [
    imageVm
  ]
}

module managementVm 'modules/managementVM.bicep' = {
  name: 'management-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, managementVmRg)
  params: {
    location: location
    adminPassword: adminPw
    adminUsername: adminUsername
    containerName: containerName
    miName: managedIdentity.name
    miResourceGroup: miResourceGroup
    securityType: securityType
    storageEndpoint: storageAccount.properties.primaryEndpoints.blob
    subnetName: subnetName
    virtualNetworkName: virtualNetwork.name
    virtualNetworkResourceGroup: split(virtualNetwork.id, '/')[4]
    vmName: managementVmName
    vmSize: vmSize
  }
  dependsOn: [
    customize
    imageVm
    managedIdentity
    gallery
  ]
}

module restart 'modules/restartVM.bicep' = {
  name: 'restart-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, managementVmRg)
  params: {
    location: location
    imageVmName: imageVm.outputs.imageVm
    imageVmRg: imageVm.outputs.imageRg
    miName: managedIdentity.name
    miResourceGroup: miResourceGroup
    cloud: cloud
    vmName: managementVmName
  }
  dependsOn: [
    customize
    imageVm
    managementVm
  ]
}

module sysprep 'modules/sysprep.bicep' = {
  name: 'sysprep-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, managementVmRg)
  params: {
    location: location
    vmName: imageVm.outputs.imageVm
    containerName: containerName
    storageAccountName: storageAccountName
    storageEndpoint: storageAccount.properties.primaryEndpoints.blob
    userAssignedIdentityObjectId: managedIdentity.properties.principalId
  }
  dependsOn: [
    customize
    imageVm
    restart
    managementVm
  ]
}

module generalizeVm 'modules/runGeneralization.bicep' = {
  name: 'generalize-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, managementVmRg)
  params: {
    location: location
    imageVmName: imageVm.outputs.imageVm
    imageVmRg: imageVm.outputs.imageRg
    miName: managedIdentity.name
    miResourceGroup: miResourceGroup
    vmName: managementVmName
    cloud: cloud
  }
  dependsOn: [
    customize
    imageVm
    managementVm
    restart
    sysprep
  ]
}

module image 'modules/gallery.bicep' = {
  name: 'gallery-image-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, galleryResourceGroup)
  params: {
    location: location
    excludeFromLatest: excludeFromLatest
    galleryName: gallery.name
    imageName: imageName
    imageVersionNumber: imageVersion
    imageVmId: imageVm.outputs.imageId
    offer: offer
    publisher: publisher
    replicaCount: replicaCount
    sku: sku
  }
  dependsOn: [
    managementVm
    customize
    generalizeVm
    restart
    sysprep
  ]
}

module remove 'modules/removeVM.bicep' = {
  name: 'remove-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, managementVmRg)
  params: {
    location: location
    imageVmName: imageVm.outputs.imageVm
    imageVmRg: imageVm.outputs.imageRg
    miName: managedIdentity.name
    miResourceGroup: miResourceGroup
    cloud: cloud
    vmName: managementVmName
  }
  dependsOn: [
    customize
    imageVm
    image
    gallery
    generalizeVm
    managementVm
    sysprep
  ]
}
