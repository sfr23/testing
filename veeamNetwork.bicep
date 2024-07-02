param location string = 'westeurope'



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
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.1.254.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
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
        name: 'Subnet-VBR'
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

resource virtualNetworkCloudDataCenter1 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vNetCloudDataCenter1'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Subnet-Mgmt'
        properties: {
          addressPrefix: '10.10.0.0/24'
        }
      }
      {
        name: 'Subnet-Mgmt2'
        properties: {
          addressPrefix: '10.10.1.0/24'
        }
      }
      {
        name: 'Subnet-WindowsServer'
        properties: {
          addressPrefix: '10.10.4.0/22'
        }
      }
      {
        name: 'Subnet-LinuxServer'
        properties: {
          addressPrefix: '10.10.8.0/22'
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
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: virtualNetworkVeeamInfrastructure.id
    }
  }
}

resource peer_VeeamIntrastructureToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  parent: virtualNetworkVeeamInfrastructure
  name: virtualNetworkVeeamInfrastructure.name
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: virtualNetworkHub.id
    }
  }
}

resource peer_HubToCloudDataCenter1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  parent: virtualNetworkHub
  name: '${virtualNetworkHub.name}_${virtualNetworkCloudDataCenter1.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: virtualNetworkCloudDataCenter1.id
    }
  }
}

resource peer_CloudDataCenter1ToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  parent: virtualNetworkCloudDataCenter1
  name: virtualNetworkCloudDataCenter1.name
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: virtualNetworkHub.id
    }
  }
}

var loginurl = environment().authentication.loginEndpoint
output ver string = loginurl

