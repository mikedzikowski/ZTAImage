param actionGroupName string
param automationAccountName string
param automationAccountPrivateDnsZoneResourceId string
param computeGalleryResourceId string
param containerName string
param customizations array
param diskEncryptionSetResourceId string
param distributionGroup string
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
param installOneDrive bool
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
param computeGalleryImageVersionResourceId string
param sourceImageType string
param storageAccountName string
param subnetResourceId string
param tags object
param teamsInstaller string
param templateSpecResourceId string
param time string = utcNow()
param timeZone string
param userAssignedIdentityClientId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param vcRedistInstaller string
param vDOTInstaller string
param virtualMachineSize string

var alerts = [
  {
    name: 'Zero Trust Image Build - Failure'
    description: 'Sends an error alert when the runbook build fails.'
    severity: 0
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category  == "JobStreams"\n| where ResultDescription has "Image build failed"'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'ResultDescription'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
  {
    name: 'Zero Trust Image Build - Success'
    description: 'Sends an informational alert when the runbook build succeeds.'
    severity: 3
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category  == "JobStreams"\n| where ResultDescription has "Image build succeeded"'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'ResultDescription'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
          operator: 'GreaterThanOrEqual'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
  }
]
var parameters = {
  computeGalleryResourceId: computeGalleryResourceId
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
  InstallOneDrive: string(installOneDrive)
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
  location: location
  managementVirtualMachineName: managementVirtualMachineName
  marketplaceImageOffer: marketplaceImageOffer
  marketplaceImagePublisher: marketplaceImagePublisher
  marketplaceImageSKU: marketplaceImageSKU
  msrdcwebrtcsvcInstaller: msrdcwebrtcsvcInstaller
  officeInstaller: officeInstaller
  replicaCount: string(replicaCount)
  resourceGroupName: resourceGroupName
  computeGalleryImageVersionResourceId: computeGalleryImageVersionResourceId
  sourceImageType: sourceImageType
  storageAccountName: storageAccountName
  subnetResourceId: subnetResourceId
  subscriptionId: subscriptionId
  tags: string(tags)
  teamsInstaller: teamsInstaller
  templateSpecResourceId: templateSpecResourceId
  tenantId: tenantId
  userAssignedIdentityClientId: userAssignedIdentityClientId
  userAssignedIdentityPrincipalId: userAssignedIdentityPrincipalId
  userAssignedIdentityResourceId: userAssignedIdentityResourceId
  vcRedistInstaller: vcRedistInstaller
  vDOTInstaller: vDOTInstaller
  virtualMachineSize: virtualMachineSize
}
var privateEndpointName = 'pe-${automationAccountName}'
var runbookName = 'New-AzureZeroTrustImageBuild'
var storageEndpoint = environment().suffixes.storage
var subscriptionId = subscription().subscriptionId
var tenantId = subscription().tenantId

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' existing = {
  name: managementVirtualMachineName
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
  tags: contains(tags, 'Microsoft.Network/privateEndpoints') ? tags['Microsoft.Network/privateEndpoints'] : {}
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

resource runCommand 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = {
  name: 'runbook'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  parent: virtualMachine
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'AutomationAccountName'
        value: automationAccountName
      }
      {
        name: 'ContainerName'
        value: containerName
      }
      {
        name: 'Environment'
        value: environment().name
      }
      {
        name: 'ResourceGroupName'
        value: resourceGroup().name
      }
      {
        name: 'RunbookName'
        value: runbookName
      }
      {
        name: 'StorageAccountName'
        value: storageAccountName
      }
      {
        name: 'StorageEndpoint'
        value: storageEndpoint
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
        name: 'UserAssignedIdentityObjectId'
        value: userAssignedIdentityPrincipalId
      }
    ]
    source: {
      script: '''
        param (
          [string]$AutomationAccountName,
          [string]$ContainerName,
          [string]$Environment,
          [string]$ResourceGroupName,
          [string]$RunbookName,
          [string]$StorageAccountName,
          [string]$StorageEndpoint,
          [string]$SubscriptionId,
          [string]$TenantId,
          [string]$UserAssignedIdentityClientId,
          [string]$UserAssignedIdentityObjectId
        )
        $ErrorActionPreference = 'Stop'
        $WarningPreference = 'SilentlyContinue'
        $BlobName = 'New-AzureZeroTrustImageBuild.ps1'
        $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
        $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
        $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
        $File = "$env:windir\temp\$BlobName"
        do
        {
            try
            {
                Write-Output "Download Attempt $i"
                Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $File
            }
            catch [System.Net.WebException]
            {
                Start-Sleep -Seconds 60
                $i++
                if($i -gt 10){throw}
                continue
            }
            catch
            {
                $Output = $_ | select *
                Write-Output $Output
                throw
            }
        }
        until(Test-Path -Path $File)
        Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity -AccountId $UserAssignedIdentityClientId | Out-Null
        Import-AzAutomationRunbook -Name $RunbookName -Path $File -Type PowerShell -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Published -Force | Out-Null
      '''
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
      parameters: replace(string(parameters), '"', '\\"')
    }
    runbook: {
      name: runbookName
    }
    runOn: hybridRunbookWorkerGroup.name
    schedule: {
      name: schedule.name
    }
  }
  dependsOn: [
    runCommand
  ]
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

resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = if (!empty(actionGroupName) && !empty(distributionGroup)) {
  name: actionGroupName
  location: 'global'
  tags: contains(tags, 'Microsoft.Insights/actionGroups') ? tags['Microsoft.Insights/actionGroups'] : {}
  properties: {
    emailReceivers: [
      {
        emailAddress: distributionGroup
        name: distributionGroup
        useCommonAlertSchema: true
      }
    ]
    enabled: true
    groupShortName: 'AIB Builds'
  }
}

resource scheduledQueryRules 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = [for i in range(0, length(alerts)): if (!empty(actionGroupName) && !empty(logAnalyticsWorkspaceResourceId)) {
  name: alerts[i].name
  location: location
  tags: contains(tags, 'Microsoft.Insights/scheduledQueryRules') ? tags['Microsoft.Insights/scheduledQueryRules'] : {}
  kind: 'LogAlert'
  properties: {
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
    autoMitigate: false
    skipQueryValidation: false
    criteria: alerts[i].criteria
    description: alerts[i].description
    displayName: alerts[i].name
    enabled: true
    evaluationFrequency: alerts[i].evaluationFrequency
    severity: alerts[i].severity
    windowSize: alerts[i].windowSize
    scopes: [
      logAnalyticsWorkspaceResourceId
    ]
  }
}]

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
  dependsOn: [
    runCommand
  ]
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
  dependsOn: [
    runCommand
  ]
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
    runCommand
  ]
}
