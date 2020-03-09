# *******************************************************************
# * Title:            Cluster Storage ReScan      
# * Purpose:          This script rescans all HBAs for new Storage
# * Args:             vCenter & Cluster Name
# * Author:           Ryan Patel
# * Creation Date:    08/07/2017
# * Last Modified:    08/07/2017
# * Version:          1.0
# *******************************************************************
# Get parameters
Param(
	[string]$LogPath = "\\SERVER\ScriptLogs\Storage\"
    )

# Enter the NEW Cluster Name
[string]$Cluster = Read-Host "Please enter the name of the Cluster:"

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d%H%M%p
$FileName = $LogPath + $Cluster + "_" + $Datestamp + ".txt"

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

# Scan the Cluster
Write-Host ""
Write-Host "Scanning Cluster: " $Cluster
Get-Cluster $Cluster | Get-VMHost | Get-VMHostStorage -RescanAllHBA -RescanVMFS
Write-Host ""
Write-Host "Scanning completed for: " $Cluster

Stop-Transcript
