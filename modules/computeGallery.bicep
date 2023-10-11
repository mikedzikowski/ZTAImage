param computeGalleryName string
param enableBuildAutomation bool
param imageDefinitionName string
param location string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param tags object
param userAssignedIdentityPrincipalId string

var roleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor | https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor

resource computeGallery 'Microsoft.Compute/galleries@2022-01-03' = {
  name: computeGalleryName
  location: location
  tags: contains(tags, 'Microsoft.Compute/galleries') ? tags['Microsoft.Compute/galleries'] : {}
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableBuildAutomation) {
  scope: computeGallery
  name: guid(userAssignedIdentityPrincipalId, roleDefinitionId, computeGallery.id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource imageDefinition 'Microsoft.Compute/galleries/images@2022-03-03' = {
  parent: computeGallery
  name: imageDefinitionName
  location: location
  tags: contains(tags, 'Microsoft.Compute/galleries') ? tags['Microsoft.Compute/galleries'] : {}
  properties: {
    architecture: 'x64'
    features: [
      {
        name: 'IsHibernateSupported'
        value: 'True'
      }
      {
        name: 'IsAcceleratedNetworkSupported'
        value: 'True'
      }
      {
        name: 'SecurityType'
        value: 'TrustedLaunch'
      }
    ]
    hyperVGeneration: 'V2'
    identifier: {
      offer: marketplaceImageOffer
      publisher: marketplaceImagePublisher
      sku: imageDefinitionName
    }
    osState: 'Generalized'
    osType: 'Windows'
  }
}

output computeGalleryResourceId string = computeGallery.id
output imageDefinitionName string = imageDefinition.name
