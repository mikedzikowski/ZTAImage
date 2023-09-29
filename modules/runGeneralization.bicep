param cloud string
param imageVirtualMachineName string
param resourceGroupName string
param location string = resourceGroup().location
param userAssignedIdentityName string
param userAssignedIdentityResourceGroupName string
param virtualMachineName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(userAssignedIdentityResourceGroupName)
  name: userAssignedIdentityName
}

resource imageVm 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  scope: resourceGroup(resourceGroupName)
  name: imageVirtualMachineName
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: virtualMachineName
}

resource generalize 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'generalize'
  location: location
  parent: vm
  properties: {
    treatFailureAsDeploymentFailure: false
    asyncExecution: false
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

        Start-Sleep 30
        
        # Generalize VM Using PowerShell
        Set-AzVm -ResourceGroupName $imageVmRg -Name $imageVmName -Generalized

        Write-Host "Generalized" 

      '''
    }
  }
}
