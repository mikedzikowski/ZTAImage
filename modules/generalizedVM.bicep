param diskEncryptionSetResourceId string
@secure()
param localAdministratorPassword string
@secure()
param localAdministratorUsername string
param location string
param marketplaceImageOffer string
param marketplaceImagePublisher string
param marketplaceImageSKU string
param subnetName string
param tags object
param userAssignedIdentityName string
param userAssignedIdentityResourceGroupName string
param virtualMachineName string
param virtualMachineSize string
param virtualNetworkName string
param virtualNetworkResourceGroupName string

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

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  scope: resourceGroup(virtualNetworkResourceGroupName)
  name: virtualNetworkName
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(userAssignedIdentityResourceGroupName)
  name: userAssignedIdentityName
}

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
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
      '${userAssignedIdentity.id}': {}
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
        publisher: marketplaceImagePublisher
        offer: marketplaceImageOffer
        sku: marketplaceImageSKU
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        managedDisk: {
          diskEncryptionSet: {
            id: diskEncryptionSetResourceId
          }
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
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
  }
}

output Name string = virtualMachine.name
output ResourceId string = virtualMachine.id
output ResourceGroupName string = split(virtualMachine.id, '/')[4]
