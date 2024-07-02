param location string = 'westeurope'
param storageAccountName string = 'dualutionsveeamtest2'
param adminUsername string = 'admin-veeamtest1'
param VeeamServerVMName string = 'VeeamBRServer'

// Storage Account Settings
param accountType string = 'Standard_LRS'
param kind string = 'StorageV2'
param minimumTlsVersion string = 'TLS1_2'
param supportsHttpsTrafficOnly bool = true
param allowBlobPublicAccess bool = false
param allowSharedKeyAccess bool = true
param defaultOAuth bool = false
param accessTier string = 'Hot'
param publicNetworkAccess string = 'Enabled'
param allowCrossTenantReplication bool = false
param networkAclsBypass string = 'AzureServices'
param networkAclsDefaultAction string = 'Allow'
param dnsEndpointType string = 'Standard'
param largeFileSharesState string = 'Enabled'
param keySource string = 'Microsoft.Storage'
param encryptionEnabled bool = true
param infrastructureEncryptionEnabled bool = false
param isBlobSoftDeleteEnabled bool = false
param blobSoftDeleteRetentionDays int = 7
param isContainerSoftDeleteEnabled bool = false
param containerSoftDeleteRetentionDays int = 7
param isShareSoftDeleteEnabled bool = true
param shareSoftDeleteRetentionDays int = 7

// VM Settings
param VeeamNetworkSecurityGroupName string = '${VeeamServerVMName}_nsg'
param networkSecurityGroupRules array = [
  {
    name: 'CloudConnect'
    properties: {
      priority: 1010
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceApplicationSecurityGroups: []
      destinationApplicationSecurityGroups: []
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: 6180
    }
  }
  {
    name: 'default-allow-rdp'
    properties: {
      priority: 1020
      protocol: 'TCP'
      access: 'Allow'
      direction: 'Inbound'
      sourceApplicationSecurityGroups: []
      destinationApplicationSecurityGroups: []
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: 3389
    }
  }
]
param subnetName string = 'Subnet-1'
param publicIpAddressName string = '${VeeamServerVMName}_publicIp'
param publicIpAddressType string = 'Static'
param publicIpAddressSku string = 'Standard'
param pipDeleteOption string = 'Detach'
param virtualMachineComputerName string = VeeamServerVMName
param osDiskType string = 'Premium_LRS'
param osDiskDeleteOption string = 'Delete'
param virtualMachineSize string = 'Standard_D2s_v3'
param nicDeleteOption string = 'Detach'
@secure()
param adminPassword string
param patchMode string = 'AutomaticByOS'
param enableHotpatching bool = false


//
var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', VeeamNetworkSecurityGroupName)
var vnetId = virtualNetworkVeeamInfrastructure.id
var subnetRef = '${vnetId}/subnets/${subnetName}'
//

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  properties: {
    minimumTlsVersion: minimumTlsVersion
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: defaultOAuth
    accessTier: accessTier
    publicNetworkAccess: publicNetworkAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    networkAcls: {
      bypass: networkAclsBypass
      defaultAction: networkAclsDefaultAction
      ipRules: []
    }
    dnsEndpointType: dnsEndpointType
    largeFileSharesState: largeFileSharesState
    encryption: {
      keySource: keySource
      services: {
        blob: {
          enabled: encryptionEnabled
        }
        file: {
          enabled: encryptionEnabled
        }
        table: {
          enabled: encryptionEnabled
        }
        queue: {
          enabled: encryptionEnabled
        }
      }
      requireInfrastructureEncryption: infrastructureEncryptionEnabled
    }
  }
  sku: {
    name: accountType
  }
  kind: kind
  tags: {}
  dependsOn: []
}

resource storageAccountName_default 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: isBlobSoftDeleteEnabled
      days: blobSoftDeleteRetentionDays
    }
    containerDeleteRetentionPolicy: {
      enabled: isContainerSoftDeleteEnabled
      days: containerSoftDeleteRetentionDays
    }
  }
}

resource Microsoft_Storage_storageAccounts_fileservices_storageAccountName_default 'Microsoft.Storage/storageAccounts/fileservices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: null
    shareDeleteRetentionPolicy: {
      enabled: isShareSoftDeleteEnabled
      days: shareSoftDeleteRetentionDays
    }
  }
  dependsOn: [
    storageAccountName_default
  ]
}


resource virtualNetworkHub 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vNetHub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Subnet-1'
        properties: {
          addressPrefix: '10.1.1.0/24'
        }
      }
    ]
  }
}

resource virtualNetworkVeeamInfrastructure 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vNetVeeamInfrastructure'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Subnet-1'
        properties: {
          addressPrefix: '10.2.0.0/24'
        }
      }
      {
        name: 'Subnet-2'
        properties: {
          addressPrefix: '10.2.1.0/24'
        }
      }
    ]
  }
}


resource peer_HubToVeaamInfrastructure 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  parent: virtualNetworkHub
  name: '${virtualNetworkHub.name}_${virtualNetworkVeeamInfrastructure.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: virtualNetworkVeeamInfrastructure.id
    }
  }
}

resource peer_ADIntrastructureToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  parent: virtualNetworkVeeamInfrastructure
  name: virtualNetworkVeeamInfrastructure.name
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: virtualNetworkHub.id
    }
  }
}




// veeam Server
resource networkInterface 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: '${VeeamServerVMName}_nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${virtualNetworkVeeamInfrastructure.id}/subnets/Subnet-1'
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', publicIpAddressName)
            properties: {
              deleteOption: pipDeleteOption
            }
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    VeeamNetworkSecurityGroup
    publicIpAddress
  ]
}

resource VeeamNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: VeeamNetworkSecurityGroupName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

resource publicIpAddress 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: publicIpAddressSku
  }
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
}

resource VeeamServerVM 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: VeeamServerVMName
  location: location
  plan: {
    name: 'veeam-backup-replication-v12'
    publisher: 'veeam'
    product: 'veeam-backup-replication'
  }
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: osDiskDeleteOption
      }
      imageReference: {
        publisher: 'veeam'
        offer: 'veeam-backup-replication'
        sku: 'veeam-backup-replication-v12'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: nicDeleteOption
          }
        }
      ]
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    osProfile: {
      computerName: virtualMachineComputerName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: enableHotpatching
          patchMode: patchMode
        }
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

output adminUsername string = adminUsername
