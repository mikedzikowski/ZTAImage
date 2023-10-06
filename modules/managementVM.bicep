param containerName string
param diskEncryptionSetResourceId string
param hybridUseBenefit bool
@secure()
param localAdministratorPassword string
@secure()
param localAdministratorUsername string
param location string
param subnetResourceId string
param tags object
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string
param virtualMachineName string

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: take('${virtualMachineName}-nic-${uniqueString(virtualMachineName)}', 15)
  location: location
  tags: contains(tags, 'Microsoft.Network/networkInterfaces') ? tags['Microsoft.Network/networkInterfaces'] : {}
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
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

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: virtualMachineName
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
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
      }
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    securityProfile: {
      encryptionAtHost: true
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    licenseType: hybridUseBenefit ? 'Windows_Server' : null
  }
}

resource modules 'Microsoft.Compute/virtualMachines/runCommands@2023-07-01' = {
  name: 'appAzModules'
  location: location
  tags: contains(tags, 'Microsoft.Compute/virtualMachines') ? tags['Microsoft.Compute/virtualMachines'] : {}
  parent: virtualMachine
  properties: {
    treatFailureAsDeploymentFailure: true
    asyncExecution: false
    parameters: [
      {
        name: 'UserAssignedIdentityObjectId'
        value: userAssignedIdentityPrincipalId
      }
      {
        name: 'ContainerName'
        value: containerName
      }
      {
        name: 'StorageEndpoint'
        value: environment().suffixes.storage
      }
      {
        name: 'BlobName'
        value: 'Az-Cmdlets-10.2.0.37547-x64.msi'
      }
      {
        name: 'Arguments'
        value: '/i Az-Cmdlets-10.2.0.37547-x64.msi /qn /norestart'
      }
    ]
    source: {
      script: '''
      param(
        [string]$UserAssignedIdentityObjectId,
        [string]$StorageAccountName,
        [string]$ContainerName,
        [string]$StorageEndpoint,
        [string]$BlobName,
        [string]$Arguments
        )
        $UserAssignedIdentityObjectId = $UserAssignedIdentityObjectId
        $ContainerName = $ContainerName
        $BlobName = $BlobName
        $StorageAccountUrl = "https://" + $StorageAccountName + ".blob." + $StorageEndpoint + "/"
        $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
        $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
        Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile "$env:windir\temp\$Blobname"
        Start-Sleep -Seconds 60
        Set-Location -Path $env:windir\temp

        # Install PowerSHell Modules
        Start-Process -FilePath msiexec.exe -ArgumentList $Arguments -Wait
        Get-InstalledModule | Where-Object {$_.name -like "Az"}
      '''
    }
  }
}
