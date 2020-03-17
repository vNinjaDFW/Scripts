#Get this function https://github.com/vNinjaDFW/Scripts/tree/master/VMware/Functions
Import-Module .\MigrateDVSwitch-Adapter.ps1 -Force

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

# Select a vCenter
Get-Content vCenterList.txt

[int]$ivCenter = Read-Host "`nSelect a vCenter Number:"

$vCenter = (Get-Content vCenterList.txt -TotalCount ($ivCenter+1))[-1]
$vCenter = $vCenter.substring(4)
$vCenter

If ($vCenter -eq 'End of List****') {
    Write-Host "Invalid Selection. Exiting."
    exit
}

Write-Host "`nYou Picked: "$vCenter `n 

Start-sleep -s 3
 
# Connect to selected vCenter
Connect-VIServer $vCenter -WarningAction SilentlyContinue

$sCluster = Get-Folder Decommission
$sHosts = Get-VMHost -Location $sCluster
$mgmt_pg = 'XXX'
$mgmt_vlan = 'XXX'
$vmotion_pg = 'XXX'
$vmotion_vlan = 'XXX'

foreach ($vmhost in $sHosts) {
Write-Host "`nProcessing" $vmhost

MigrateDVSwitch-Adapter -VMHost $vmhost -Interface vmk0 -NetworkName $mgmt_pg -VirtualSwitch vSwitch0 -vlan $mgmt_vlan
MigrateDVSwitch-Adapter -VMHost $vmhost -Interface vmk1 -NetworkName $vmotion_pg -VirtualSwitch vSwitch0 -vlan $vmotion_vlan

}

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false
