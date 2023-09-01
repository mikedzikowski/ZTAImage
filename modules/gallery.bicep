targetScope = 'resourceGroup'
param offer string
param publisher string
param sku string
param excludeFromLatest bool
param replicaCount int
param replicationMode string = 'Full'
param storageAccountType string = 'Standard_LRS'
param hyperVGeneration string = 'V2'
param galleryName string
param location string = resourceGroup().location
param imageName string
param imageVersionNumber string
param imageVmId string
param allowDeletionOfReplicatedLocations bool = true

resource gallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: galleryName
}

resource image 'Microsoft.Compute/galleries/images@2022-03-03' = {
  name: '${imageName}-${sku}'
  location: location
  parent: gallery
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
      offer: offer
      publisher: publisher
      sku: '${sku}-${imageName}'
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
        id: imageVmId
      }
    }
  }
}
