targetScope = 'resourceGroup'

param allowDeletionOfReplicatedLocations bool = true
param excludeFromLatest bool
param galleryName string
param hyperVGeneration string = 'V2'
param imageDefinitionName string
param imageVersionNumber string
param imageVirtualMachineResourceId string
param location string = resourceGroup().location
param marketplaceImageOffer string
param marketplaceImagePublisher string
param replicaCount int
param replicationMode string = 'Full'
param storageAccountType string = 'Standard_LRS'

resource gallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: galleryName
}

resource image 'Microsoft.Compute/galleries/images@2022-03-03' = {
  parent: gallery
  name: imageDefinitionName
  location: location
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
    hyperVGeneration: hyperVGeneration
    identifier: {
      offer: marketplaceImageOffer
      publisher: marketplaceImagePublisher
      sku: imageDefinitionName
    }
    osState: 'Generalized'
    osType: 'Windows'
  }
}

resource imageVersion 'Microsoft.Compute/galleries/images/versions@2022-03-03' = {
  name: imageVersionNumber
  location: location
  parent: image
  properties: {
    publishingProfile: {
      excludeFromLatest: excludeFromLatest
      replicaCount: replicaCount
      replicationMode: replicationMode
      storageAccountType: storageAccountType
      targetRegions: [
        {
          excludeFromLatest: excludeFromLatest
          name: location
          regionalReplicaCount: replicaCount
          storageAccountType: storageAccountType
        }
      ]
    }
    safetyProfile: {
      allowDeletionOfReplicatedLocations: allowDeletionOfReplicatedLocations
    }
    storageProfile: {
      source: {
        id: imageVirtualMachineResourceId
      }
    }
  }
}

output galleryName string = gallery.name
output imageDefinitionName string = image.name
