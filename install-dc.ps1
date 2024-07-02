param (
    $RecoveryPassword,
    $DomainName,
    $domainNetBIOSName
)
# Ensure the script is running as an administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "You need to run this script as an administrator."
    exit
}

# Variables
$SafeModeAdminPassword = (ConvertTo-SecureString $RecoveryPassword -AsPlainText -Force)  # Change this to a secure password

# Install the AD-Domain-Services feature
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Import the ADDSDeployment module
Import-Module ADDSDeployment

# Create a new forest and make this server the first domain controller
Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetBIOSName $domainNetBIOSName `
    -SafeModeAdministratorPassword $SafeModeAdminPassword `
    -InstallDNS `
    -Force

# Wait for the server to reboot
Write-Output "The server will now restart to complete the domain controller installation."
Restart-Computer -Force
