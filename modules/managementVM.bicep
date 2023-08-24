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

param cloud string

param storageEndpoint string
param imageVmName string
param imageVmRg string

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

resource imageVm 'Microsoft.Compute/virtualMachines@2022-03-01' existing = {
  scope: resourceGroup(imageVmRg)
  name: imageVmName
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, subnetName)
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

resource applications 'Microsoft.Compute/virtualMachines/runCommands@2023-03-01' = [ for installer in installers: if(installer.enabled) {
  name: 'app-${installer.name}'
  location: location
  parent: vm
  properties: {
    treatFailureAsDeploymentFailure: true
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
        name: 'Blobname'
        value: installer.blobName
      }
      {
        name: 'Arguments'
        value: installer.arguments
      }
      {
        name: 'miId'
        value: managedIdentity.properties.clientId
      }
      {
        name: 'imageVmRg'
        value: split(imageVm.id, '/')[4]
      }
      {
        name: 'imageVmName'
        value: imageVm.name
      }
      {
        name: 'Environment'
        value: cloud
      }
    ]
    source: {
      script: '''
      param(
        [string]$miId,
        [string]$UserAssignedIdentityObjectId,
        [string]$ContainerName,
        [string]$StorageEndpoint,
        [string]$BlobName,
        [string]$Arguments,
        [string]$imageVmRg,
        [string]$imageVmName,
        [string]$Environment
        )
        $UserAssignedIdentityObjectId = $UserAssignedIdentityObjectId
        $ContainerName = $ContainerName
        $BlobName = $BlobName
        $StorageAccountUrl = $StorageEndpoint
        $TokenUri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$StorageAccountUrl&object_id=$UserAssignedIdentityObjectId"
        $AccessToken = ((Invoke-WebRequest -Headers @{Metadata=$true} -Uri $TokenUri -UseBasicParsing).Content | ConvertFrom-Json).access_token
        Invoke-WebRequest -Headers @{"x-ms-version"="2017-11-09"; Authorization ="Bearer $AccessToken"} -Uri "$StorageAccountUrl$ContainerName/$BlobName" -OutFile $env:windir\temp\$BlobName
        Start-Sleep -Seconds 30
        Set-Location -Path $env:windir\temp

        # Install PowerSHell Modules
        Start-Process -FilePath msiexec.exe -Wait -ArgumentList $Arguments

        # Connect to Azure
        Connect-AzAccount -Identity -AccountId $miId -Environment $Environment # Run on the virtual machine
        # Get Vm using PowerShell
        $sourceVM = Get-AzVM -Name $imageVmName -ResourceGroupName $imageVmRg
        # Generalize VM Using PowerShell
        Set-AzVm -ResourceGroupName $sourceVM.ResourceGroupName -Name $sourceVm.Name -Generalized

        # Remove Image VM and Management VM
        Remove-AzVM -Name $sourceVm.Name -ForceDeletion $true -Force -ResourceGroupName $sourceVM.ResourceGroupName -NoWait
        #Remove-AzVM -Name $sourceVm.Name -ForceDeletion $true -Force -ResourceGroupName $sourceVM.ResourceGroupName -NoWait
      '''
    }
  }
}]
