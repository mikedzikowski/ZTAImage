param imageVirtualMachineName string
param resourceGroupName string
param location string
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

resource restartVm 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = {
  name: 'restartVm'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  parent: vm
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'Environment'
        value: environment().name
      }
      {
        name: 'ResourceGroupName'
        value: split(imageVm.id, '/')[4]
      }
      {
        name: 'SubscriptionId'
        value: subscription().subscriptionId
      }
      {
        name: 'TenantId'
        value: tenant().tenantId
      }
      {
        name: 'UserAssignedIdentityClientId'
        value: userAssignedIdentityClientId
      }
      {
        name: 'VirtualMachineName'
        value: imageVm.name
      }
    ]
    source: {
      script: '''
        param(
          [string]$Environment,
          [string]$ResourceGroupName,
          [string]$SubscriptionId,
          [string]$TenantId,
          [string]$UserAssignedIdentityClientId,
          [string]$VirtualMachineName,
        )
        $ErrorActionPreference = 'Stop'
        $WarningPreference = 'SilentlyContinue'
        Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity -AccountId $UserAssignedIdentityClientId | Out-Null
        Restart-AzVM -Name $VirtualMachineName -ResourceGroupName $ResourceGroupName
        $lastProvisioningState = ""
        $provisioningState = (Get-AzVM -resourcegroupname $ResourceGroupName -name $VirtualMachineName -Status).Statuses[1].Code
        $condition = ($provisioningState -eq "PowerState/running")
        while (!$condition) {
          if ($lastProvisioningState -ne $provisioningState) {
            write-host $VirtualMachineName "under" $ResourceGroupName "is" $provisioningState "(waiting for state change)"
          }
          $lastProvisioningState = $provisioningState
          Start-Sleep -Seconds 5
          $provisioningState = (Get-AzVM -resourcegroupname $ResourceGroupName -name $VirtualMachineName -Status).Statuses[1].Code
          $condition = ($provisioningState -eq "PowerState/running")
        }
        write-host $VirtualMachineName "under" $ResourceGroupName "is" $provisioningState
        start-sleep 30
      '''
    }
  }
}
