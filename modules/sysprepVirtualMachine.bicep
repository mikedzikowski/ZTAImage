targetScope = 'resourceGroup'

param location string
param tags object
param virtualMachineName string

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-11-01' existing = {
  name: virtualMachineName
}

resource sysprepVirtualMachine 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = {
  parent: virtualMachine
  name: 'sysprepVirtualMachine'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
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