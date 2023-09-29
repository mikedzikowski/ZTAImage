param containerName string
param diskEncryptionSetResourceId string
param hybridUseBenefit bool
@secure()
param localAdministratorPassword string
@secure()
param localAdministratorUsername string
param location string
param userAssignedIdentityName string
param userAssignedIdentityResourceGroupName string
param storageEndpoint string
param subnetName string
param tags object
param virtualNetworkName string
param virtualNetworkResourceGroup string
param virtualMachineName string
param virtualMachineSize string

var installers = [
  {
    name: 'AzModules'
    blobName: 'Az-Cmdlets-10.2.0.37547-x64.msi'
    arguments: '/i Az-Cmdlets-10.2.0.37547-x64.msi /qn /norestart'
    enabled: true
  }
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroup)
  name: virtualNetworkName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(userAssignedIdentityResourceGroupName)
  name: userAssignedIdentityName
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: 'nsg-image-vm'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: take('${virtualMachineName}-nic-${uniqueString(virtualMachineName)}', 15)
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${virtualNetwork.id}/subnets/${subnetName}'
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: virtualMachineName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: localAdministratorUsername
      adminPassword: localAdministratorPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter-core-g2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetResourceId
          }
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: []
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
    licenseType: hybridUseBenefit ? 'Window_Server' : null
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource modules 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = [for installer in installers: if (installer.enabled) {
  name: 'app${installer.name}'
  location: location
  tags: tags
  parent: virtualMachine
  properties: {
    parameters: [
      {
        name: 'UserAssignedIdentityObjectId'
        value: managedIdentity.properties.principalId
      }
      {
        name: 'ContainerName'
        value: containerName
      }
      {
        name: 'StorageEndpoint'
        value: storageEndpoint
      }
      {
        name: 'BlobName'
        value: installer.blobName
      }
      {
        name: 'Arguments'
        value: installer.arguments
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
        $StorageAccountUrl = $StorageEndpoint
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
}]
