Import-Module POSH-HPOneView-4.20\HPOneView.420.psd1
[String]$Location = "Backup Folder Location"

$user = 'Administrator'
$password = 'hp1nvent'

Connect-HPOVMgmt -Hostname $hostname -AuthLoginDomain Local -UserName $user -Password $password
New-HPOVBackup -Location $Location
Disconnect-HPOVMgmt