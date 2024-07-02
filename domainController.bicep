// New parameters for VM creation
@description('The name of the virtual machine')
param vmDC1 string = 'dc1'
param domainName string = 'dom3.local'
param domainNetbiosName string = 'dom3'


@description('Admin username for the VM')
param adminUsername string = 'admin-veeamtest1'

@secure()
@minLength(12)
@description('Admin password for the VM')
param adminPassword string


@description('The size of the virtual machine')
param vmSize string = 'Standard_D2s_v3'

@description('Windows Server 2022 image reference')
param windows2022ImageReference object = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2022-Datacenter'
  version: 'latest'
}

param networkRG string = 'ASHCI'
param subnetName string = 'Subnet-WindowsServer'
param location string = resourceGroup().location


resource virtualNetworkforServer 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: 'vNetCloudDataCenter1'
  scope: resourceGroup(networkRG)
}

resource vmDC1_nic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: '${vmDC1}_nic1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${vmDC1}_ipconfig'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          privateIPAddress: '10.10.4.10'
          subnet: {
            id: '${virtualNetworkforServer.id}/subnets/${subnetName}'
          }
        }
      }
    ]
  }
}

resource vm1 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmDC1
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmDC1
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: windows2022ImageReference.publisher
        offer: windows2022ImageReference.offer
        sku: windows2022ImageReference.sku
        version: windows2022ImageReference.version
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmDC1_nic.id

        }
      ]
    }
    
  }
  identity: {
      type: 'SystemAssigned'
   }
}


resource windowsVMGuestConfigExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vm1
  name: 'AzurePolicyforWindows'
  location: location
  properties: {
    publisher: 'Microsoft.GuestConfiguration'
    type: 'ConfigurationforWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {}
    protectedSettings: {}
  }
}



resource windowsVMExtensions 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vm1
  name: 'name'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/sfr23/testing/main/vmscripts/install-dc.ps1'
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Bypass -file install-dc.ps1 -RecoveryPassword ${adminPassword} -DomainName ${domainName} -domainNetBIOSName ${domainNetbiosName}'
    }
  }
}

/////

resource AdminCenterExtension 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  parent: vm1
  name: 'AdminCenter'
  location: location
  properties: {
    publisher: 'Microsoft.AdminCenter'
    type: 'AdminCenter'
    typeHandlerVersion: '0.0'
    autoUpgradeMinorVersion: true
    settings: {
      port: '6516'
    }
  }
}
