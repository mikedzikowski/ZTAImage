
@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the virtual machine.')
param vmName string

param miName string

@description('Name of the virtual machine.')
param miResourceGroup string

param cloud string

param imageVmName string
param imageVmRg string


resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(miResourceGroup)
  name: miName
}

resource imageVm 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  scope: resourceGroup(imageVmRg)
  name: imageVmName
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: vmName
}

resource removeVm 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'removeVm'
  location: location
  parent: vm
  properties: {
    treatFailureAsDeploymentFailure: false
    asyncExecution: true
    parameters: [
      {
        name: 'miId'
        value: managedIdentity.properties.clientId
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

        Remove-AzVM -Name $imageVmName -ResourceGroupName $imageVmRg -Nowait -ForceDeletion $true -Force

        start-sleep 60

        Remove-AzVM -Name $managementVmName -ResourceGroupName $managementVmRg -NoWait -ForceDeletion $true -Force -AsJob
      '''
    }
  }
}
