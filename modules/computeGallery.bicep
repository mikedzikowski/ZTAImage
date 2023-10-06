param computeGalleryName string
param imageDefinitionName string
param location string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param tags object

resource computeGallery 'Microsoft.Compute/galleries@2022-01-03' = {
  name: computeGalleryName
  location: location
  tags: contains(tags, 'Microsoft.Compute/galleries') ? tags['Microsoft.Compute/galleries'] : {}
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
