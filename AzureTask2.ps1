#Install-Module -Name Az
#Connect-AzAccount

$ResourceGroupName = 'NSM_group'
$Location = 'EastUS'

New-AzResourceGroup -Name $ResourceGroupName -Location $Location

$VaultName = 'VaronisAssignmentKv9'
New-AzKeyVault -Name $VaultName -ResourceGroupName $ResourceGroupName -Location $Location



Get-AzADUser

$KVAccessPolicy = @{
    UserPrincipalName         = 'nivshemer_gmail.com#EXT#@nivshemergmail.onmicrosoft.com'
    VaultName                 = $VaultName
    ResourceGroupName         = $ResourceGroupName
    PermissionsToCertificates = @('Get','List','Delete','Create','Import','Update','Managecontacts','Getissuers','Listissuers','Setissuers','Deleteissuers','Manageissuers','Recover','Backup','Restore','Purge')
    PermissionsToKeys         = @('Decrypt','Encrypt','UnwrapKey','WrapKey','Verify','Sign','Get','List','Update','Create','Import','Delete','Backup','Restore','Recover','Purge')
    PermissionsToSecrets      = @('Get','List','Set','Delete','Backup','Restore','Recover','Purge')

}

Set-AzKeyVaultAccessPolicy @KVAccessPolicy


$Cred = Get-Credential

$SecretString = ConvertTo-SecureString -AsPlainText -Force -String ($Cred.UserName + "`v" + $Cred.GetNetworkCredential().Password)


Set-AzKeyVaultSecret -VaultName $VaultName -Name 'TestCredential' -SecretValue $SecretString -ContentType 'PSCredential'
#https://varonisassignmentkv9.vault.azure.net:443/secrets/TestCredential/871b1d08bb744f51b964b6cada10ff3b


$VaultName = 'VaronisAssignmentKv9'

$Secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name 'TestCredential'
$Secret.SecretValueText


$Cred = New-Object System.Management.Automation.PSCredential (
    ((Get-AzKeyVaultSecret -VaultName $VaultName -Name 'TestCredential').SecretValueText -Split "`v")[0],
    (ConvertTo-SecureString ((Get-AzKeyVaultSecret -VaultName $VaultName -Name 'TestCredential').SecretValueText -Split "`v")[1] -AsPlainText -Force)
)





# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

$Cred = New-Object System.Management.Automation.PSCredential (
    ($env:TestCredential -Split "`v")[0],
    (ConvertTo-SecureString ($env:TestCredential -Split "`v")[1] -AsPlainText -Force)
)

Write-Host "The Key Vault secret username is: $($Cred.UserName)"
Write-Host "The Key Vault secret password is: $($Cred.GetNetworkCredential().Password)"
