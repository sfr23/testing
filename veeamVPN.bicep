param vpnGWname string = 'vpngw42'
param DNSAlias string = 'dualutionstestvpn42'

param location string = resourceGroup().location
param tenantId string = 'f8c928a3-4f96-405d-8fce-b52f95ddf54b'

@description('Alle oder eine bestimme Gruppe zulassen')
//param aadAudience string = 'c632b3df-fb67-4d84-bdcf-b95ad541b5c8' //alle
param aadAudience string = '3a03013f-847d-4416-bc7b-84914adc31f6' // User der Enterprise App 'VPNuser'

@description('Tenant ID')
param aadTenant string = '${environment().authentication.loginEndpoint}${tenantId}'
@description('Tenant ID')
param aadIssuer string = 'https://sts.windows.net/${tenantId}/'


////////////////////////// static
@allowed([
  'Vpn'
  'ExpressRoute'
])
param gatewayType string = 'Vpn'
param sku string = 'VpnGw1'
param vpnGatewayGeneration string = 'Generation1'
param subnetId string = 'GatewaySubnet'

@allowed([
  'RouteBased'
  'PolicyBased'
])
param vpnType string = 'RouteBased'
param newPublicIpAddressName string = '${vpnGWname}-PublicIp'

resource vNetHub 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: 'vNetHub'
}


resource newPublicIpAddress 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: newPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: []
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: DNSAlias
      fqdn: '${DNSAlias}.westeurope.cloudapp.azure.com'
    }
  }
}

resource vpnGWname_resource 'Microsoft.Network/virtualNetworkGateways@2023-11-01' = {
  name: vpnGWname
  location: 'westeurope'
  properties: {
    enablePrivateIpAddress: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('ASHCI', 'Microsoft.Network/publicIPAddresses', newPublicIpAddressName)
          }
          subnet: {
            id: '${vNetHub.id}/subnets/${subnetId}'
          }
        }
      }
    ]
    natRules: []
    virtualNetworkGatewayPolicyGroups: []
    enableBgpRouteTranslationForNat: false
    disableIPSecReplayProtection: false
    sku: {
      name: sku
      tier: sku
    }
    gatewayType: gatewayType
    vpnType: vpnType
    enableBgp: false
    activeActive: false
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          '10.100.254.0/24'
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'AAD'
      ]
      vpnClientRootCertificates: []
      vpnClientRevokedCertificates: []
      vngClientConnectionConfigurations: []
      radiusServers: []
      vpnClientIpsecPolicies: []
      aadTenant: aadTenant
      aadAudience: aadAudience
      aadIssuer: aadIssuer
    }
    
    customRoutes: {
      addressPrefixes: [
        '10.2.0.0/24'  
      ]
    }
    vpnGatewayGeneration: vpnGatewayGeneration
    allowRemoteVnetTraffic: false
    allowVirtualWanTraffic: false
  }
  dependsOn: [
    newPublicIpAddress
  ]
}

output publicIP string = newPublicIpAddress.properties.ipAddress
output vpnAudience string = vpnGWname_resource.properties.vpnClientConfiguration.aadAudience
output vpnClientConfig array = vpnGWname_resource.properties.vpnClientConfiguration.vngClientConnectionConfigurations
output publicDNS string = newPublicIpAddress.properties.dnsSettings.domainNameLabel
