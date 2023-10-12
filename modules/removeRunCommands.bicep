param location string
param tags object
param timestamp string = utcNow('yyyyMMddhhmmss')
param virtualMachineName string

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' existing = {
  name: virtualMachineName
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: virtualMachine
  name: 'CustomScriptExtension'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      timestamp: timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -Command {Get-AzResource -ResourceGroupName "${resourceGroup().name}" -ResourceType "Microsoft.Compute/virtualMachines/runCommands" | Remove-AzResource -Force | Out-Null}'
    }
  }
}
