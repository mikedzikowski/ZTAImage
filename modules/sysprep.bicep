targetScope = 'resourceGroup'

param containerName string
param location string
param storageAccountName string
param storageEndpoint string
param tags object
param userAssignedIdentityObjectId string
param virtualMachineName string

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: virtualMachineName
}

resource sysprep 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = {
  name: 'sysprep'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  parent: vm
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'ContainerName'
        value: containerName
      }
      {
        name: 'StorageAccountName'
        value: storageAccountName
      }
      {
        name: 'StorageEndpoint'
        value: storageEndpoint
      }
      {
        name: 'UserAssignedIdentityObjectId'
        value: userAssignedIdentityObjectId
      }
    ]
    source: {
      script: '''
        param(
          [string]$ContainerName,
          [string]$StorageAccountName,
          [string]$StorageEndpoint,
          [string]$UserAssignedIdentityObjectId
        )
        $BlobName = 'New-PepareVHDToUploadToAzure.ps1'
        $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
        $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
        $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
        Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $env:windir\temp\$BlobName
        Start-Sleep -Seconds 60
        Set-Location -Path $env:windir\temp
        .\New-PepareVHDToUploadToAzure.ps1
      '''
    }
  }
  dependsOn: []
}
