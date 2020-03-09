<#
SYNOPSIS
	Unmount & Detach Datastore
Description
	This script unmounts and detaches Datastore from all hosts (typically a Cluster)
.NOTES
    File Name		: Unmount_Detach_Datastore.ps1
    Author			: Ryan Patel
    Prerequisite	: DatastoreFunctions, vCenter, Cluster, Datastore
    Creation Date	: 10/6/2017
	Version			: 1.0
	Update Log:
#>
# Enter the name of Datastore
[string]$Datastore = (Read-Host "Please enter the name of the datastore to be unmounted and detached:")

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\Storage\"
$FileName = $LogPath + $Datastore + "_" + $Datestamp + ".txt"

# Start Logging
$Timestart = Get-Date
Start-Transcript $FileName

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

Write-Host "`nYou Picked: "$vCenter `n -ForegroundColor Blue

Start-sleep -s 3
 
# Connect to selected vCenter
Connect-VIServer $vCenter -WarningAction SilentlyContinue

# Configuration Changes
Get-Datastore $Datastore | Get-DatastoreMountInfo | Sort Datastore, VMHost | FT -AutoSize
Get-Datastore $Datastore | Unmount-Datastore
Get-Datastore $Datastore | Get-DatastoreMountInfo | Sort Datastore, VMHost | FT -AutoSize
Get-Datastore $Datastore | Detach-Datastore
Get-Datastore $Datastore | Get-DatastoreMountInfo | Sort Datastore, VMHost | FT -AutoSize

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false

Stop-Transcript
