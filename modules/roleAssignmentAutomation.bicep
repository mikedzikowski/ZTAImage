param principalId string

var roleDefinitionId = 'f353d9bd-d4a6-484e-a77a-8050b599b867' // Automation Contributor | https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#automation-contributor

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, roleDefinitionId, resourceGroup().name)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
