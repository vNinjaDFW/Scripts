<#
SYNOPSIS
	pNIC migration from vDS to vSS
Description
	Migrate single pNIC from vDS to vSS
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

function usage {
  echo ""
  write-host "Mig-vmnic5.ps1 [-help] | [-p NIC Mode Setting] " -foregroundcolor "white"
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

$sCluster = Get-Folder Decommission
$sHosts = Get-VMHost -Location $sCluster

  foreach ($ESXHost in $sHosts) {
  # Remove pNIC from vDS
	write-host "Removing pNIC5 from vDS on host: " $ESXHost -ForegroundColor Red
	Get-VMHostNetworkAdapter -VMHost $ESXHost -Physical -Name vmnic5 | Remove-VDSwitchPhysicalNetworkAdapter -Confirm:$false
	timeout 1
	$myStandardSwitch = Get-VirtualSwitch -VMHost $ESXHost -Standard
	Set-VirtualSwitch $myStandardSwitch -Mtu 9000 -Confirm:$false
	$physicalNic = Get-VMHostNetworkAdapter -VMHost $ESXHost -Physical -Name vmnic5
	write-host "Removed!"  -ForegroundColor White

  # Adding pNIC to VSS
	write-host "Adding NIC to Std Switch on host: " $ESXHost -ForegroundColor Yellow
	Add-VirtualSwitchPhysicalNetworkAdapter -VirtualSwitch $myStandardSwitch -VMHostPhysicalNic $physicalNic -Confirm:$false
	$policy = Get-VirtualSwitch -VMHost $ESXHost -Name $myStandardSwitch | Get-NicTeamingPolicy
	If ($NicSetting -eq "Standby") { 
		$policy | Set-NicTeamingPolicy -MakeNicStandby $physicalNic
	} elseif ($NicSetting -eq "Active") {
		$policy | Set-NicTeamingPolicy -MakeNicActive $physicalNic
	}
	write-host "Added!"  -ForegroundColor White
  }

# Disconnect from vCenter
Disconnect-VIServer * -confirm:$false

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
