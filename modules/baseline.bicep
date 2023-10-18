targetScope = 'subscription'

param computeGalleryImageResourceId string
param computeGalleryName string
param containerName string
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
param enableBuildAutomation bool
param exemptPolicyAssignmentIds array
param hybridUseBenefit bool
param imageDefinitionName string
@secure()
param localAdministratorPassword string
param localAdministratorUsername string
param location string
param managementVirtualMachineName string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param resourceGroupName string
param storageAccountResourceId string
param subnetResourceId string
param subscriptionId string
param tags object
param userAssignedIdentityName string

module userAssignedIdentity 'userAssignedIdentity.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'user-assigned-identity-${deploymentNameSuffix}'
  params: {
    location: location
    name: userAssignedIdentityName
    tags: tags
  }
}

module roleAssignments 'roleAssignments.bicep' = {
  name: 'role-assignment-compute-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    principalId: userAssignedIdentity.outputs.principalId
  }
}

module storageAccount 'storageAccount.bicep' = {
  name: 'role-assignment-storage-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, split(storageAccountResourceId, '/')[4])
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    storageAccountResourceId: storageAccountResourceId
  }
}

module diskEncryptionSet 'diskEncryptionSet.bicep' = {
  scope: resourceGroup(split(diskEncryptionSetResourceId, '/')[2], split(diskEncryptionSetResourceId, '/')[4])
  name: 'disk-encryption-set-${deploymentNameSuffix}'
  params: {
    diskEncryptionSetName: split(diskEncryptionSetResourceId, '/')[8]
    principalId: userAssignedIdentity.outputs.principalId
  }
}

module managementVM 'managementVM.bicep' = {
  name: 'management-vm-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    containerName: containerName
    diskEncryptionSetResourceId: diskEncryptionSetResourceId 
    hybridUseBenefit: hybridUseBenefit
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    storageAccountName: split(storageAccountResourceId, '/')[8]
    subnetResourceId: subnetResourceId
    tags: tags
    userAssignedIdentityPrincipalId: userAssignedIdentity.outputs.principalId 
    userAssignedIdentityResourceId: userAssignedIdentity.outputs.resourceId
    virtualMachineName: managementVirtualMachineName
  }
}

module computeGallery 'computeGallery.bicep' = {
  name: 'gallery-image-${deploymentNameSuffix}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    computeGalleryImageResourceId: computeGalleryImageResourceId
    enableBuildAutomation: enableBuildAutomation
    imageDefinitionName: imageDefinitionName
    location: location
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    computeGalleryName: computeGalleryName
    tags: tags
    userAssignedIdentityPrincipalId: userAssignedIdentity.outputs.principalId
  }
}

module policyExemptions 'exemption.bicep' = [for i in range(0, length(exemptPolicyAssignmentIds)): if (length(exemptPolicyAssignmentIds) > 0) {
  name: 'PolicyExemption_${i}'
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    policyAssignmentId: exemptPolicyAssignmentIds[i]
  }
}]

output computeGalleryResourceId string = computeGallery.outputs.computeGalleryResourceId
output userAssignedIdentityClientId string = userAssignedIdentity.outputs.clientId
output userAssignedIdentityPrincipalId string = userAssignedIdentity.outputs.principalId
output userAssignedIdentityResourceId string = userAssignedIdentity.outputs.resourceId
