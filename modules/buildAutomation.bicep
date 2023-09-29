targetScope = 'subscription'

param automationAccountName string
param containerName string
param customizations array
param deploymentNameSuffix string
param diskEncryptionSetResourceId string
@secure()
param domainJoinPassword string
param domainJoinUserPrincipalName string
param domainName string
param galleryName string
param galleryResourceGroupName string
param hybridUseBenefit bool
param hybridWorkerVirtualMachineName string
param imageDefinitionName string
param imageMajorVersion int
param imageMinorVersion int
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
param resourceGroupName string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param marketplaceImageSKU string
param msrdcwebrtcsvcInstaller string
param officeInstaller string
param oUPath string
param replicaCount int
param securityPrincipalObjectIds array
param sourceImageType string
param storageAccountName string
param storageAccountResourceGroupName string
param subnetName string
param subscriptionId string
param tags object
param teamsInstaller string
param tenantType string
param timeZone string
param userAssignedIdentityName string
param userAssignedIdentityResourceGroupName string
param vcRedistInstaller string
param vDOTInstaller string
param virtualMachineName string
param virtualNetworkName string
param virtualNetworkResourceGroupName string
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
    securityPrincipalObjectIds: securityPrincipalObjectIds
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
    containerName: containerName
    customizations: customizations
    diskEncryptionSetResourceId: diskEncryptionSetResourceId
    domainJoinPassword: domainJoinPassword
    domainJoinUserPrincipalName: domainJoinUserPrincipalName
    domainName: domainName
    galleryName: galleryName
    galleryResourceGroupName: galleryResourceGroupName
    hybridUseBenefit: hybridUseBenefit
    hybridWorkerVirtualMachineName: hybridWorkerVirtualMachineName
    imageDefinitionName: imageDefinitionName
    imageMajorVersion: imageMajorVersion
    imageMinorVersion: imageMinorVersion
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
    localAdministratorPassword: localAdministratorPassword
    localAdministratorUsername: localAdministratorUsername
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    resourceGroupName: resourceGroupName
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageSKU: marketplaceImageSKU
    msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
    officeInstaller: officeInstaller
    oUPath: oUPath
    replicaCount: replicaCount
    sourceImageType: sourceImageType
    storageAccountName: storageAccountName
    storageAccountResourceGroupName: storageAccountResourceGroupName
    subnetName: subnetName
    tags: tags
    teamsInstaller: teamsInstaller
    templateSpecResourceId: templateSpec.outputs.resourceId
    tenantType: tenantType
    timeZone: timeZone
    userAssignedIdentityName: userAssignedIdentityName
    userAssignedIdentityResourceGroupName: userAssignedIdentityResourceGroupName
    vcRedistInstaller: vcRedistInstaller
    vDOTInstaller: vDOTInstaller
    virtualMachineName: virtualMachineName
    virtualMachineSize: virtualMachineSize
    virtualNetworkName: virtualNetworkName
    virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
  }
}
