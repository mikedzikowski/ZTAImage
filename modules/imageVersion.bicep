param allowDeletionOfReplicatedLocations bool = true
param computeGalleryName string
param diskEncryptionSetResourceId string
param excludeFromLatest bool
param imageDefinitionName string
param imageVersionNumber string
param imageVirtualMachineResourceId string
param location string
param replicaCount int
param tags object

resource computeGallery 'Microsoft.Compute/galleries@2022-01-03' existing = {
  name: computeGalleryName
}

resource imageDefinition 'Microsoft.Compute/galleries/images@2022-03-03' existing = {
  parent: computeGallery
  name: imageDefinitionName
}

resource imageVersion 'Microsoft.Compute/galleries/images/versions@2022-03-03' = {
  parent: imageDefinition
  name: imageVersionNumber
  location: location
  tags: contains(tags, 'Microsoft.Compute/galleries') ? tags['Microsoft.Compute/galleries'] : {}
  properties: {
    publishingProfile: {
      excludeFromLatest: excludeFromLatest
      replicaCount: replicaCount
      replicationMode: 'Full'
      storageAccountType: 'Standard_LRS'
      targetRegions: [
        {
          /* Not supported yet: https://learn.microsoft.com/en-us/azure/virtual-machines/image-version-encryption#limitations
          encryption: {
            osDiskImage: {
              diskEncryptionSetId: diskEncryptionSetResourceId
            }
          } 
          */
          name: location
          regionalReplicaCount: replicaCount
          storageAccountType: 'Standard_LRS'
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
