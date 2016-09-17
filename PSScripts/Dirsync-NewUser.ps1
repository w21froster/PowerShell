#William F. - 2/10/16 - New Office 365 User via DirSync
Import-Module ActiveDirectory
Import-Module DirSync

#Create user and set properties and attributes
$User = Read-Host -Prompt 'Enter desired username (Example: jdoe)'
$DisplayName = Read-Host -Prompt 'Enter desired display name (Example: John Doe)'
$Email = Read-Host -Prompt 'Enter desired email address (Example: JDoe@yourdomain.com)'
$Firstname = Read-Host -Prompt 'Enter users first name'
$Lastname = Read-Host -Prompt 'Enter users last name'
$FirstHalf = ($Email -replace "@.*")
$Path = Get-ADDomain | select -expandproperty UsersContainer
$Password = Read-Host -Prompt "Enter password" -AsSecureString

New-ADUser `
 -Name $User `
 -Path  $Path `
 -SamAccountName  $User `
 -DisplayName $DisplayName `
 -GivenName $Firstname `
 -Surname $Lastname `
 -EmailAddress $Email `
 -AccountPassword $Password `
 -ChangePasswordAtLogon $false  `
 -UserPrincipalName $Email `
 -Enabled $true

Set-ADUser $User -Add @{ProxyAddresses="SMTP:$($Email)"}
Set-ADUser $User -Add @{targetAddress="SMTP:$($Email)"}

#Start Office365 synchronization
Start-OnlineCoexistenceSync

