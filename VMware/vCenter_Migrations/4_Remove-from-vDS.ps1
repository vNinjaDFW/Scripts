<#
SYNOPSIS
	Second pNIC migration from vDS to vSS & vDS Removal
Description
	Migrate second pNIC from vDS to vSS & removes Host from vDS
.NOTES
#>

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

$vds = Get-VDSwitch
$sCluster = Get-Folder XXX
$sHosts = Get-VMHost -Location $sCluster

foreach ($ESXHost in $sHosts) {
	# Removes the specified host physical network adapter from the vSphere distributed switch
	Write-host "Removing NIC from vDS on host: " $ESXHost -ForegroundColor Yellow
	$ESXHost | Get-VMHostNetworkAdapter -Physical -Name vmnic5 | Remove-VDSwitchPhysicalNetworkAdapter -Confirm:$false
	timeout 1

	# Removes the specified host from the vSphere distributed switch
	write-host "Removing Host: " $ESXHost "from vDS: " $vds_name -ForegroundColor Red
	$vds | Remove-VDSwitchVMHost -VMHost $ESXHost -Confirm:$false
	write-host "Completed!" -ForegroundColor White
}

# Disconnect from vCenter
Disconnect-VIServer * -confirm:$false

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
