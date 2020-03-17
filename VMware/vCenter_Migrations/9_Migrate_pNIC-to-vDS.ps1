<#
SYNOPSIS
	pNIC migration from vSS to vDS
Description
	Migrate single pNIC from vSS to vDS
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

$svds = Get-VDSwitch

function usage {
  echo ""
  write-host "Mig-vmnic4.ps1 [-help] | [-p NIC Mode Setting] " -foregroundcolor "white"
  echo ""
  write-host "-help prints this information" -foregroundcolor "yellow"
  echo ""
  write-host "-p specify Standby or Active (req)" -foregroundcolor "yellow"
  echo ""
  exit
}

if ("-help","--help","-?","--?","/?" -contains $args[0]) {
  usage
}

$NicSetting = @()
# check to see if we are using a file for input or if command-line arguments
if ("-p" -contains $args[0]) {
  $NicSetting=$args[1]
} else { 
    usage
}

$sCluster = Get-Cluster RPE1_Linux
$sHosts = $sCluster | Get-VMHost

  foreach ($ESXHost in $sHosts) {
  # Remove pNIC from vSS
 	$physicalNic = Get-VMHostNetworkAdapter -VMHost $ESXHost -Physical -Name vmnic4
 	Write-Host "Removing vmnic4 on host: " $ESXHost -ForegroundColor Yellow
	$physicalNic | Remove-VirtualSwitchPhysicalNetworkAdapter -Confirm:$false
	write-host "Done!"  -ForegroundColor White
	timeout 1
    
  # Add pNIC to vDS
	Write-Host "Adding vmnic4 as vDS Standby uplink for Host: " $ESXHost -ForegroundColor Red
	$hostsPhysicalNic = $ESXHost | Get-VMHostNetworkAdapter -Name "vmnic4"
	Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $hostsPhysicalNic -DistributedSwitch $svds -Confirm:$false
	Write-Host "Completed!" -ForegroundColor White
	}

# Disconnect from vCenter
Disconnect-VIServer * -confirm:$false

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
