targetScope = 'resourceGroup'

param vmName string
param location string = resourceGroup().location
param userAssignedIdentityObjectId string = '258d3674-d759-4fe1-bddf-13413e16a6a7'
param storageAccontName string = 'saimageartifacts'
param containerName string = 'artifacts'
param sysprepBlobName string = 'Get-ScriptToPrepareVHD.ps1'
param notepadBlobName string = 'Get-Notepad++.ps1'

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' existing  = {
  name: vmName
}

resource notepad 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = {
  name: 'notepad'
  location: location
  parent: vm
  properties: {
    source: {
      scriptUri: 'https://saimageartifacts.blob.core.usgovcloudapi.net/artifacts/Get-NotePad++.ps1' 
    }
    parameters: [
      {
        name: 'UserAssignedIdentityObjectId'
        value: userAssignedIdentityObjectId
      }
      {
        name: 'StorageAccontName'
        value: storageAccontName
      }
      {
        name: 'ContainerName'
        value: containerName
      }
      {
        name: 'BlobName'
        value: notepadBlobName
      }
    ]
    timeoutInSeconds: 120
  }
}

resource sysprep 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = {
  name: 'sysprep'
  location: location
  parent: vm
  properties: {
    source: {
      scriptUri: 'https://saimageartifacts.blob.core.usgovcloudapi.net/artifacts/Get-ScriptToPrepareVHD.ps1'
    }
    parameters: [
      {
        name: 'UserAssignedIdentityObjectId'
        value: userAssignedIdentityObjectId
      }
      {
        name: 'StorageAccontName'
        value: storageAccontName
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
     notepad
  ]
}
