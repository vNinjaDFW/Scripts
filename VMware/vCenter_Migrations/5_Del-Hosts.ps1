<#
SYNOPSIS
	Remove Host from vCenter
Description
	Removes Hosts in specified Cluster from vCenter
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

$sCluster = Get-Folder XXX
$sHosts = Get-VMHost -Location $sCluster

foreach ($ESXHost in $sHosts) {
	Get-VMHost $ESXHost | Remove-VMHost -Confirm:$false
  }

# Disconnect from vCenter
Disconnect-VIServer * -confirm:$false

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
