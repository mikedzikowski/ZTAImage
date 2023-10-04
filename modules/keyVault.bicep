@secure()
param domainJoinPassword string
@secure()
param domainJoinUserPrincipalName string
param keyVaultName string
param location string
@secure()
param localAdministratorPassword string
@secure()
param localAdministratorUsername string
param roleDefinitionResourceId string
param tags object
param userAssignedIdentityPrincipalId string

var Secrets = [
  {
    name: 'DomainJoinPassword'
    value: domainJoinPassword
  }
  {
    name: 'DomainJoinUserPrincipalName'
    value: domainJoinUserPrincipalName
  }
  {
    name: 'LocalAdministratorPassword'
    value: localAdministratorPassword
  }
  {
    name: 'LocalAdministratorUsername'
    value: localAdministratorUsername
  }
]

// The Key Vault stores the secrets to deploy virtual machines
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyVaultName
  location: location
  tags: contains(tags, 'Microsoft.KeyVault/vaults') ? tags['Microsoft.KeyVault/vaults'] : {}
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: false
    publicNetworkAccess: 'Enabled'
  }
}

resource secrets 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = [for Secret in Secrets: {
  parent: keyVault
  name: Secret.name
  tags: contains(tags, 'Microsoft.KeyVault/vaults') ? tags['Microsoft.KeyVault/vaults'] : {}
  properties: {
    value: Secret.value
  }
}]

// Gives the selected users rights to get key vault secrets in deployments
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(userAssignedIdentityPrincipalId, roleDefinitionResourceId, resourceGroup().id)
  scope: keyVault
  properties: {
    roleDefinitionId: roleDefinitionResourceId
    principalId: userAssignedIdentityPrincipalId
  }
}

output resourceId string = keyVault.id
