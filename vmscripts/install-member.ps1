param(
    $dnsServer,
    $DomainName,
    $domainUser,
    $domainPW
)
$interfaceIndex = (Get-NetAdapter).ifIndex
Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses $dnsServer


$securePassword = ConvertTo-SecureString $domainPW -AsPlainText -Force

# Create a PSCredential object
$credential = New-Object System.Management.Automation.PSCredential ("$DomainName\$domainUser", $securePassword)

# Join the server to the domain
Add-Computer -DomainName $domainName -Credential $credential -Restart