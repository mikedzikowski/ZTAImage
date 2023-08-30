
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

resource restartVm 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'restartVm'
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
        [string]$Environment
        )
        # Connect to Azure
        Connect-AzAccount -Identity -AccountId $miId -Environment $Environment # Run on the virtual machine
        # Restart VM
        Restart-AzVM -Name $imageVmName -ResourceGroupName $imageVmRg

        $lastProvisioningState = ""
        $provisioningState = (Get-AzVM -resourcegroupname $imageVmRg -name $imageVmName -Status).Statuses[1].Code
        $condition = ($provisioningState -eq "PowerState/running")
        while (!$condition) {
          if ($lastProvisioningState -ne $provisioningState) {
            write-host $imageVmName "under" $imageVmRg "is" $provisioningState "(waiting for state change)"
          }
          $lastProvisioningState = $provisioningState

          Start-Sleep -Seconds 5
          $provisioningState = (Get-AzVM -resourcegroupname $imageVmRg -name $imageVmName -Status).Statuses[1].Code

          $condition = ($provisioningState -eq "PowerState/running")
        }
        write-host $imageVmName "under" $imageVmRg "is" $provisioningState
        start-sleep 30
      '''
    }
  }
}
