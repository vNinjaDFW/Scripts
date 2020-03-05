# Select the Source vCenter
Get-Content vCenterList.txt

[int]$ivCenter = Read-Host "`nSelect a vCenter Number:"

$svCenter = (Get-Content vCenterList.txt -TotalCount ($ivCenter+1))[-1]
$svCenter = $svCenter.substring(4)
$svCenter

If ($svCenter -eq 'End of List****') {
    Write-Host "Invalid Selection. Exiting."
    exit
}

Write-Host "`nYou Picked: "$svCenter `n 

# Select the Destination vCenter
Get-Content vCenterList.txt

[int]$ivCenter = Read-Host "`nSelect a vCenter Number:"

$dvCenter = (Get-Content vCenterList.txt -TotalCount ($ivCenter+1))[-1]
$dvCenter = $dvCenter.substring(4)
$dvCenter

If ($dvCenter -eq 'End of List****') {
    Write-Host "Invalid Selection. Exiting."
    exit
}

Write-Host "`nYou Picked: "$dvCenter `n 

Start-sleep -s 3

# Connect to both the source and destination vCenters
Write-Host "Connecting to $svCenter and $dvCenter..." -Foregroundcolor "Yellow" -NoNewLine
Connect-viserver -server $svCenter, $dvCenter

# Get roles to transfer
$roles = get-virole -server $svCenter
 
# Get role Privileges
foreach ($role in $roles) {
[string[]]$privsforRoleAfromsvCenter=Get-VIPrivilege -Role (Get-VIRole -Name $role -server $svCenter) |%{$_.id}
 
# Create new role in dvCenter
New-VIRole -name $role -Server $dvCenter
 
# Add Privileges to new role.
Set-VIRole -role (get-virole -Name $role -Server $dvCenter) -AddPrivilege (get-viprivilege -id $privsforRoleAfromsvCenter -server $dvCenter)
}

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black

# Disconnect from vCenter
Disconnect-VIServer * -confirm:$false
