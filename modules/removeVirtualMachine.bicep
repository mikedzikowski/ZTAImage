param enableBuildAutomation bool
param imageVirtualMachineName string
param location string = resourceGroup().location
param tags object
param userAssignedIdentityClientId string
param virtualMachineName string

resource imageVirtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: imageVirtualMachineName
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  name: virtualMachineName
}

resource removeVirtualMachine 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = {
  parent: virtualMachine
  name: 'removeVirtualMachine'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    treatFailureAsDeploymentFailure: false
    asyncExecution: true
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
        value: imageVirtualMachine.name
      }
      {
        name: 'ManagementVmName'
        value: virtualMachine.name
      }
      {
        name: 'ResourceGroupName'
        value: resourceGroup().name
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
        Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $ImageVmName -NoWait -Force -AsJob
        if($EnableBuildAutomation -eq 'false')
        {
          Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $ManagementVmName -NoWait -Force -AsJob
        }
      '''
    }
  }
}
