targetScope = 'resourceGroup'

param location string
param tags object
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
    treatFailureAsDeploymentFailure: false
    asyncExecution: true
    parameters: []
    source: {
      script: '''
        $ErrorActionPreference = 'Stop'
        Start-Process -File "C:\Windows\System32\Sysprep\Sysprep.exe" -ArgumentList "/generalize /oobe /shutdown /mode:vm"
      '''
    }
  }
}
