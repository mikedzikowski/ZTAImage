@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@secure()
param adminPassword string

@description('Size of the virtual machine.')
param vmSize string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the virtual machine.')
param vmName string

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string
param miName string

@description('Name of the virtual machine.')
param miResourceGroup string

@description('Name of the virtual machine.')
param virtualNetworkResourceGroup string
param virtualNetworkName string

param subnetName string

param containerName string

param storageEndpoint string

var installers = [
  {
    name: 'AzModules'
    blobName: 'Az-Cmdlets-10.2.0.37547-x64.msi'
    arguments: '/i Az-Cmdlets-10.2.0.37547-x64.msi /qn /norestart'
    enabled: true
  }
]

var nicName = '${vmName}-nic'
var networkSecurityGroupName = 'nsg-image-vm'
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroup)
  name: virtualNetworkName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(miResourceGroup)
  name: miName
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: networkSecurityGroupName
  location: location
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

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: location
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

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
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
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties:{
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
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource modules 'Microsoft.Compute/virtualMachines/runCommands@2022-11-01' = [ for installer in installers: if(installer.enabled) {
  name: 'app${installer.name}'
  location: location
  parent: vm
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
        Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $env:windir\temp\$Blobname
        Start-Sleep -Seconds 30
        Set-Location -Path $env:windir\temp

        # Install PowerSHell Modules
        Start-Process -FilePath msiexec.exe -ArgumentList $Arguments -Wait
        Get-InstalledModule | Where-Object {$_.name -like "Az"}
      '''
    }
  }
  dependsOn: [
  ]
}]
