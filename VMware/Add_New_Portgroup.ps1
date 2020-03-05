# *******************************************************************
# * Title:            Add new vDS-portgroup
# * Purpose:          This script add new Portgroup(s) to the
# *                   select vDS.
# * Args:             vCenter & vDS                                                             
# * Author:           Ryan Patel
# * Creation Date:    08/08/2017
# * Last Modified:    08/08/2017
# * Version:          1.0
# *******************************************************************
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

[string]$pgName = (Read-Host "Please enter the name of the NEW Portgroup:")
[string]$numPorts = (Read-Host "Please enter the number of ports for the portgroup:")
[string]$vLanID = (Read-Host "Please enter the vLAN ID:")


#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\rp1rrinas01\platform\ScriptLogs\Portgroups\"
$FileName = $LogPath + $vCenter + "_" + $pgName + "_" + $Datestamp + ".txt"

# Start Logging
$Timestart = Get-Date
Start-Transcript $FileName

# Connect to selected vCenter
Connect-VIServer $vCenter -WarningAction SilentlyContinue

# Select the vDS
Write-Host ""
Write-Host "Choose which vDS to create the Portgroup in:"
Write-Host ""
$ivDS = Get-VDSwitch | Select Name | Sort-object Name
$i = 1
$ivDS | %{Write-Host $i":" $_.Name; $i++}
$dvDS = Read-Host "Enter the number for the vDS:"
$svDS = $ivDS[$dvDS -1].Name
Write-Host "You picked:" $svDS"."

# Create Portgroup
Write-Host "Creating new Portgroup"
Get-VDSwitch $svDS | New-VDPortgroup -Name $pgName -NumPorts $numPorts -vLanID $vLanID | Out-Null
Get-VDPortgroup -Name $pgName | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -LoadBalancingPolicy ExplicitFailover -ActiveUplinkPort dvUplink1 -StandbyUplinkPort dvUplink2

# Disconnect from vCenter
Disconnect-VIServer $vCenter -Confirm:$false

# Stop Logging
Stop-Transcript