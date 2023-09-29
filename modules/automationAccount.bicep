param automationAccountName string
param containerName string
param customizations array
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
param jobScheduleName string = newGuid()
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
param sharedGalleryImageResourceId string
param sourceImageType string
param storageAccountName string
param storageAccountResourceGroupName string
param subnetName string
param tags object
param teamsInstaller string
param templateSpecResourceId string
param tenantType string
param time string = utcNow()
param timeZone string
param userAssignedIdentityName string
param userAssignedIdentityResourceGroupName string
param vcRedistInstaller string
param vDOTInstaller string
param virtualMachineName string
param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualMachineSize string

var environmentName = environment().name
var runbookName = 'Zero-Trust-Image-Build-Automation'
var subnetResourceId = resourceId(virtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var subscriptionId = subscription().subscriptionId
var tenantId = subscription().tenantId

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: take('${virtualMachineName}-nic-${uniqueString(virtualMachineName)}', 15)
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetResourceId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachineName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-core-g2'
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetResourceId
          }
          storageAccountType: 'Premium_LRS'
        }
        osType: 'Windows'
      }
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: localAdministratorUsername
      adminPassword: localAdministratorPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    securityProfile: {
      encryptionAtHost: true
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    licenseType: hybridUseBenefit ? 'Window_Server' : null
  }
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' = {
  name: automationAccountName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    disableLocalAuth: false
    sku: {
      name: 'Basic'
    }
    encryption: {
      keySource: 'Microsoft.Automation'
      identity: {}
    }
  }
}

resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: runbookName
  location: location
  tags: tags
  properties: {
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    publishContentLink: {
      uri: ''
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
    startTime: dateTimeAdd(time, 'PT15M')
    timeZone: timeZone
  }
}

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = {
  parent: automationAccount
  #disable-next-line use-stable-resource-identifiers
  name: jobScheduleName
  properties: {
    parameters: {
      automationAccountName: automationAccountName
      containerName: containerName
      customizations: string(customizations)
      deploymentType: 'ImageBuild'
      diskEncryptionSetResourceId: diskEncryptionSetResourceId
      environmentName: environmentName
      galleryName: galleryName
      galleryResourceGroup: galleryResourceGroupName
      hybridUseBenefit: string(hybridUseBenefit)
      hybridWorkerVirtualMachineName: hybridWorkerVirtualMachineName
      imageDefinitionName: imageDefinitionName
      imageMajorVersion: string(imageMajorVersion)
      imageMinorVersion: string(imageMinorVersion)
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
      localAdministratorPassword: localAdministratorPassword
      localAdministratorUsername: localAdministratorUsername
      location: location
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
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
      storageAccountResourceGroupName: storageAccountResourceGroupName
      subnetName: subnetName
      subscriptionId: subscriptionId
      tags: string(tags)
      teamsInstaller: teamsInstaller
      templateSpecResourceId: templateSpecResourceId
      tenantId: tenantId
      tenantType: tenantType
      userAssignedIdentityName: userAssignedIdentityName
      userAssignedIdentityResourceGroupName: userAssignedIdentityResourceGroupName
      vcRedistInstaller: vcRedistInstaller
      vDOTInstaller: vDOTInstaller
      virtualMachineName: hybridWorkerVirtualMachineName
      virtualNetworkName: virtualNetworkName
      virtualNetworkResourceGroupName: virtualNetworkResourceGroupName
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
  properties: {
    credential: {}
  }
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
  tags: tags
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

resource extension_JsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = if (!empty(domainJoinUserPrincipalName) && !empty(oUPath)) {
  parent: virtualMachine
  name: 'JsonADDomainExtension'
  location: location
  tags: tags
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
