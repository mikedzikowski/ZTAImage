targetScope = 'resourceGroup'

param vmName string
param location string = resourceGroup().location

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
    timeoutInSeconds: 120
  }
}

resource sysprep 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = {
  name: 'sysprep'
  location: location
  parent: vm
  properties: {
    outputBlobUri: 'https://saimageartifacts.blob.core.usgovcloudapi.net/artifacts/errors.txt'
    source: {
      // script:'\${Env:windir}\\system32\\sysprep\\Sysprep.exe /generalize /oobe /shutdown /mode:vm'
      scriptUri: 'https://saimageartifacts.blob.core.usgovcloudapi.net/artifacts/Get-ScriptToPrepareVHD.ps1'
    }
    timeoutInSeconds: 120
  }
  dependsOn: [
     notepad
  ]
}
