param cloud string
param imageVirtualMachineName string
param resourceGroupName string
param location string
param tags object
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

resource restartVm 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = {
  name: 'restartVm'
  location: location
  tags: tags
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
