param automationAccountName string
param automationAccountPrivateDnsZoneResourceId string
param computeGalleryName string
param containerName string
param customizations array
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
param jobScheduleName string = newGuid()
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
param tags object
param teamsInstaller string
param templateSpecResourceId string
param tenantType string
param time string = utcNow()
param timeZone string
param userAssignedIdentityClientId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param vcRedistInstaller string
param vDOTInstaller string
param virtualMachineName string
param virtualMachineSize string

var privateEndpointName = 'pe-${automationAccountName}'
var runbookName = 'Zero-Trust-Image-Build-Automation'
var subscriptionId = subscription().subscriptionId
var tenantId = subscription().tenantId

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' existing = {
  name: virtualMachineName
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' = {
  name: automationAccountName
  location: location
  tags: contains(tags, 'Microsoft.Automation/automationAccounts') ? tags['Microsoft.Automation/automationAccounts'] : {}
  properties: {
    disableLocalAuth: false
    publicNetworkAccess: false
    sku: {
      name: 'Basic'
    }
    encryption: {
      keySource: 'Microsoft.Automation'
      identity: {}
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        id: resourceId('Microsoft.Network/privateEndpoints/privateLinkServiceConnections', privateEndpointName, privateEndpointName)
        properties: {
          privateLinkServiceId: automationAccount.id
          groupIds: [
            'DSCAndHybridWorker'
          ]
        }
      }
    ]
    customNetworkInterfaceName: 'nic-${automationAccountName}'
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azure-automation-net'
        properties: {
          privateDnsZoneId: automationAccountPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: runbookName
  location: location
  tags: contains(tags, 'Microsoft.Automation/automationAccounts') ? tags['Microsoft.Automation/automationAccounts'] : {}
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: 'https://${storageAccountName}.blob.${environment().suffixes.storage}/${containerName}/New-AzureZeroTrustImageBuild.ps1'
      version: '1.0.0.0'
    }
  }
}

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2022-08-08' = {
  parent: automationAccount
  name: imageDefinitionName
  properties: {
    frequency: 'Day'
    interval: 1
    startTime: dateTimeAdd(time, 'P1D')
    timeZone: timeZone
  }
}

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = {
  parent: automationAccount
  #disable-next-line use-stable-resource-identifiers
  name: jobScheduleName
  properties: {
    parameters: {
      computeGalleryName: computeGalleryName
      containerName: containerName
      customizations: string(customizations)
      diskEncryptionSetResourceId: diskEncryptionSetResourceId
      enableBuildAutomation: string(enableBuildAutomation)
      environmentName: environment().name
      imageDefinitionName: imageDefinitionName
      imageMajorVersion: string(imageMajorVersion)
      imageMinorVersion: string(imageMinorVersion)
      imageVirtualMachineName: imageVirtualMachineName
      installAccess: string(installAccess)
      installExcel: string(installExcel)
      installOneDriveForBusiness: string(installOneDriveForBusiness)
      installOneNote: string(installOneNote)
      installOutlook: string(installOutlook)
      installPowerPoint: string(installPowerPoint)
      installProject: string(installProject)
      installPublisher: string(installPublisher)
      installSkypeForBusiness: string(installSkypeForBusiness)
      installTeams: string(installTeams)
      installVirtualDesktopOptimizationTool: string(installVirtualDesktopOptimizationTool)
      installVisio: string(installVisio)
      installWord: string(installWord)
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
      replicaCount: string(replicaCount)
      resourceGroupName: resourceGroupName
      sharedGalleryImageResourceId: sharedGalleryImageResourceId
      sourceImageType: sourceImageType
      storageAccountName: storageAccountName
      subnetResourceId: subnetResourceId
      subscriptionId: subscriptionId
      tags: string(tags)
      teamsInstaller: teamsInstaller
      templateSpecResourceId: templateSpecResourceId
      tenantId: tenantId
      tenantType: tenantType
      userAssignedIdentityClient: userAssignedIdentityClientId
      userAssignedIdentityPrincipalId: userAssignedIdentityPrincipalId
      userAssignedIdentityResourceId: userAssignedIdentityResourceId
      vcRedistInstaller: vcRedistInstaller
      vDOTInstaller: vDOTInstaller
      virtualMachineSize: virtualMachineSize
    }
    runbook: {
      name: runbook.name
    }
    runOn: hybridRunbookWorkerGroup.name
    schedule: {
      name: schedule.name
    }
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (!empty(logAnalyticsWorkspaceResourceId)) {
  scope: automationAccount
  name: 'diag-${automationAccount.name}'
  properties: {
    logs: [
      {
        category: 'JobLogs'
        enabled: true
      }
      {
        category: 'JobStreams'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

resource hybridRunbookWorkerGroup 'Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups@2022-08-08' = {
  parent: automationAccount
  name: 'Zero Trust Image Build Automation'
}

resource hybridRunbookWorker 'Microsoft.Automation/automationAccounts/hybridRunbookWorkerGroups/hybridRunbookWorkers@2022-08-08' = {
  parent: hybridRunbookWorkerGroup
  name: guid(hybridRunbookWorkerGroup.id)
  properties: {
    vmResourceId: virtualMachine.id
  }
}

resource extension_HybridWorker 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: virtualMachine
  name: 'HybridWorkerForWindows'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    publisher: 'Microsoft.Azure.Automation.HybridWorker'
    type: 'HybridWorkerForWindows'
    typeHandlerVersion: '1.1'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AutomationAccountURL: automationAccount.properties.automationHybridServiceUrl
    }
  }
}

resource extension_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (!empty(domainJoinUserPrincipalName) && !empty(domainName) && !empty(oUPath)) {
  parent: virtualMachine
  name: 'JsonADDomainExtension'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  properties: {
    forceUpdateTag: time
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainName
      User: domainJoinUserPrincipalName
      Restart: 'true'
      Options: '3'
      OUPath: oUPath
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
  dependsOn: [
    extension_HybridWorker
  ]
}

output principalId string =  automationAccount.identity.principalId
