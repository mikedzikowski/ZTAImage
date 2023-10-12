param enableBuildAutomation bool
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
    asyncExecution: enableBuildAutomation ? true : false
    parameters: [
      {
        name: 'EnableBuildAutomation'
        value: string(enableBuildAutomation)
      }
      {
        name: 'Environment'
        value: environment().name
      }
      {
        name: 'ImageVmName'
        value: imageVm.name
      }
      {
        name: 'ManagementVmName'
        value: vm.name
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
    ]
    source: {
      script: '''
        param(
          [string]$EnableBuildAutomation,
          [string]$Environment,
          [string]$ImageVmName,
          [string]$ManagementVmName,
          [string]$ResourceGroupName,
          [string]$SubscriptionId,
          [string]$TenantId,
          [string]$UserAssignedIdentityClientId
        )
        $ErrorActionPreference = 'Stop'
        Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity -AccountId $UserAssignedIdentityClientId | Out-Null
        Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $ImageVmName -Force
        if($EnableBuildAutomation -eq 'false')
        {
          Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $ManagementVmName -NoWait -Force -AsJob
        }
      '''
    }
  }
}
