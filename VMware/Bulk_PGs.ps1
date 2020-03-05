<#
SYNOPSIS
	Bulk Add Portgroups
Description
	This script adds Portgroups from CSV file.
.NOTES
    File Name		: Bulk_Add_PGs.ps1
    Author			: Ryan Patel
    Prerequisite	: vCenter
    Creation Date	: 03/13/2019
	Version			: 1.0
	Update Log:
#>
#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\rp1rrinas01\platform\ScriptLogs\Portgroups\"
$FileName = $LogPath + $Datastore + "_" + $Datestamp + ".txt"

# Start Logging
$Timestart = Get-Date
Start-Transcript $FileName

# Select a vCenter
Get-Content vCenterList.txt

[int]$ivCenter = Read-Host "`nSelect a vCenter Number:"

$vCenter = (Get-Content vCenterList.txt -TotalCount ($ivCenter+1))[-1]
$vCenter = $vCenter.substring(4)

If ($vCenter -eq 'End of List****') {
    Write-Host "Invalid Selection. Exiting."
    exit
}
 
Write-Host "`nYou Picked: "$vCenter `n
Start-sleep -s 3
 
# Connect to selected vCenter
Connect-VIServer $vCenter -WarningAction SilentlyContinue

# Select Bulk PG Source
$sfile = Select-FileDialog -Title "Select the CSV Source File" -Directory (Get-Location) -Filter "CSV Files (*.csv)|*.csv"
$vdsPortgroup = Import-Csv $sfile
 
Write-Host
 
foreach ($portgroup in $vdsPortgroup){
	Get-VDSwitch $portgroup.vDS | New-VDPortgroup -name $portgroup.pgName -NumPorts $portgroup.numports -VlanId $portgroup.vlanID
}

Write-Host "`nPortgroups created. Now confirming settings" -ForegroundColor Blue

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false