targetScope = 'resourceGroup'

param vmName string
param location string = resourceGroup().location
param userAssignedIdentityObjectId string = '258d3674-d759-4fe1-bddf-13413e16a6a7'
param storageAccountName string = 'saimageartifacts'
param containerName string = 'artifacts'
param sysprepBlobName string = 'Get-ScriptToPrepareVHD.ps1'
param notepadBlobName string = 'Get-Notepad++.ps1'
param storageEndpoint string = '.blob.core.usgovcloudapi.net'


var software = [
  notepadBlobName
]

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' existing  = {
  name: vmName
}

resource customization 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = [for (blob, i) in software:  {
  name: 'softwareinstall-${i}'
  location: location
  parent: vm
  properties: {
    source: {
      scriptUri: 'https://${storageAccountName}${storageEndpoint}/${containerName}/${blob}'
    }
    parameters: [
      {
        name: 'UserAssignedIdentityObjectId'
        value: userAssignedIdentityObjectId
      }
      {
        name: 'StorageAccontName'
        value: storageAccountName
      }
      {
        name: 'ContainerName'
        value: containerName
      }
      {
        name: 'BlobName'
        value: blob
      }
    ]
    timeoutInSeconds: 360
  }
}]

resource sysprep 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = {
  name: 'sysprep'
  location: location
  parent: vm
  properties: {
    source: {
      scriptUri: 'https://${storageAccountName}${storageEndpoint}/${containerName}/${sysprepBlobName}'
    }
    parameters: [
      {
        name: 'UserAssignedIdentityObjectId'
        value: userAssignedIdentityObjectId
      }
      {
        name: 'StorageAccontName'
        value: storageAccountName
      }
      {
        name: 'ContainerName'
        value: containerName
      }
      {
        name: 'BlobName'
        value: sysprepBlobName
      }
    ]
    timeoutInSeconds: 120
  }
  dependsOn: [
     customization
  ]
}
