targetScope = 'subscription'

param automationAccountName string
param automationAccountPrivateDnsZoneResourceId string
param computeGalleryName string
param containerName string
param customizations array
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param enableBuildAutomation bool
param imageDefinitionName string
param imageMajorVersion int
param imageMinorVersion int
param imageVirtualMachineName string
param installAccess bool
param installExcel bool
param installOneDriveForBusiness bool
param installOneNote bool
param installOutlook bool
param installPowerPoint bool
param installProject bool
param installPublisher bool
param installSkypeForBusiness bool
param installTeams bool
param installVirtualDesktopOptimizationTool bool
param installVisio bool
param installWord bool
param keyVaultName string
@secure()
param localAdministratorPassword string
param localAdministratorUsername string
param location string
param logAnalyticsWorkspaceResourceId string
param managementVirtualMachineName string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param marketplaceImageSKU string
param msrdcwebrtcsvcInstaller string
param officeInstaller string
param oUPath string
param replicaCount int
param resourceGroupName string
param sharedGalleryImageResourceId string
param sourceImageType string
param storageAccountName string
param subnetResourceId string
param subscriptionId string
param tags object
param teamsInstaller string
param tenantType string
param timeZone string
param userAssignedIdentityClientId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param vcRedistInstaller string
param vDOTInstaller string
param virtualMachineName string
param virtualMachineSize string

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, 'KeyVaultDeployAction')
  properties: {
    roleName: 'KeyVaultDeployAction_${subscription().subscriptionId}'
    description: 'Allows a principal to get but not view Key Vault secrets for ARM template deployments.'
    assignableScopes: [
      subscription().id
    ]
    permissions: [
      {
        actions: [
          'Microsoft.KeyVault/vaults/deploy/action'
        ]
      }
    ]
  }
}

module keyVault 'keyVault.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'key-vault-${deploymentNameSuffix}'
  params: {
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    keyVaultName: keyVaultName
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    roleDefinitionResourceId: roleDefinition.id
    tags: tags
    userAssignedIdentityPrincipalId: userAssignedIdentityPrincipalId
  }
}

module templateSpec 'templateSpec.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'template-spec-${deploymentNameSuffix}'
  params: {
    imageDefinitionName: imageDefinitionName
    location: location
    tags: tags
  }
}

module automationAccount 'automationAccount.bicep' = {
  scope: resourceGroup(subscriptionId, resourceGroupName)
  name: 'automation-account-${deploymentNameSuffix}'
  params: {
    automationAccountName: automationAccountName
    automationAccountPrivateDnsZoneResourceId: automationAccountPrivateDnsZoneResourceId
    computeGalleryName: computeGalleryName
    containerName: containerName
    customizations: customizations
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    enableBuildAutomation: enableBuildAutomation
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
    imageVirtualMachineName: imageVirtualMachineName
    installAccess: installAccess
    installExcel: installExcel
    installOneDriveForBusiness: installOneDriveForBusiness
    installOneNote: installOneNote
    installOutlook: installOutlook
    installPowerPoint: installPowerPoint
    installProject: installProject
    installPublisher: installPublisher
    installSkypeForBusiness: installSkypeForBusiness
    installTeams: installTeams
    installVirtualDesktopOptimizationTool: installVirtualDesktopOptimizationTool
    installVisio: installVisio
    installWord: installWord
    keyVaultName: keyVaultName
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    managementVirtualMachineName: managementVirtualMachineName
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    oUPath: oUPath
    replicaCount: replicaCount
    resourceGroupName: resourceGroupName
    sharedGalleryImageResourceId: sharedGalleryImageResourceId
    sourceImageType: sourceImageType
    storageAccountName: storageAccountName
    subnetResourceId: subnetResourceId
    tags: tags
    teamsInstaller: teamsInstaller
    templateSpecResourceId: templateSpec.outputs.resourceId
    tenantType: tenantType
    timeZone: timeZone
    userAssignedIdentityClientId: userAssignedIdentityClientId
    userAssignedIdentityPrincipalId: userAssignedIdentityPrincipalId
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
    vcRedistInstaller: vcRedistInstaller
    vDOTInstaller: vDOTInstaller
    virtualMachineName: virtualMachineName
    virtualMachineSize: virtualMachineSize
  }
}
