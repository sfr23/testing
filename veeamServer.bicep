param location string = 'westeurope'
param adminUsername string = 'admin-veeamtest1'
param VeeamServerVMName string = 'VeeamBRServer'



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
param subnetName string = 'Subnet-VBR'
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

//


resource virtualNetworkforVBRServer 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: 'vNetVeeamInfrastructure'
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
            id: '${virtualNetworkforVBRServer.id}/subnets/${subnetName}'
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
