param cloud string
param imageVirtualMachineName string
param resourceGroupName string
param location string = resourceGroup().location
param tags object
param userAssignedIdentityClientId string
param virtualMachineName string

resource imageVm 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  scope: resourceGroup(resourceGroupName)
  name: imageVirtualMachineName
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: virtualMachineName
}

resource removeVm 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = {
  name: 'removeVm'
  location: location
  parent: vm
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: true
    parameters: [
      {
        name: 'miId'
        value: userAssignedIdentityClientId
      }
      {
        name: 'imageVmRg'
        value: split(imageVm.id, '/')[4]
      }
      {
        name: 'imageVmName'
        value: imageVm.name
      }
      {
        name: 'managementVmRg'
        value: split(vm.id, '/')[4]
      }
      {
        name: 'managementVmName'
        value: vm.name
      }
      {
        name: 'Environment'
        value: cloud
      }
    ]
    source: {
      script: '''
      param(
        [string]$miId,
        [string]$imageVmRg,
        [string]$imageVmName,
        [string]$managementVmRg,
        [string]$managementVmName,
        [string]$Environment
        )
        # Connect to Azure
        Connect-AzAccount -Identity -AccountId $miId -Environment $Environment # Run on the virtual machine

        # Remove Image VM and Management VM

        Remove-AzVM -Name $imageVmName -ResourceGroupName $imageVmRg -ForceDeletion $true -Force

        Remove-AzVM -Name $managementVmName -ResourceGroupName $managementVmRg -NoWait -ForceDeletion $true -Force -AsJob
      '''
    }
  }
}
