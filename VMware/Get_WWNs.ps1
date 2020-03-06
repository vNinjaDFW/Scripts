# *******************************************************************
# * Title:            Get Cluster WWN Information
# * Purpose:          This script gets the WWNs of the selected
# *                   ESXi Cluster.
# * Args:             vCenter & Cluster Name
# * Author:           Ryan Patel
# * Creation Date:    08/21/2017
# * Last Modified:    08/21/2017
# * Version:          1.0
# *******************************************************************
[string]$LogPath = "\\SERVER\ScriptLogs\Storage\"

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d%H%M%p
$FileName = $LogPath + $sCluster + "_" + $Datestamp + ".txt"

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

Write-Host "`nYou Picked: "$vCenter `n 

Start-sleep -s 3
 
# Connect to selected vCenter
Connect-VIServer $vCenter -WarningAction SilentlyContinue

ForEach ($sCluster in (Get-Cluster)){
Get-Cluster $sCluster | select Name,@{N="Host Count"; E={($_ | Get-VMHost).Count}}
Get-Cluster $sCluster | Get-VMHost | Get-VMHostHBA | Select VMHost,HBA,WWN,SpeedGbps | Sort-Object VMHost | FT -AutoSize
}

Stop-Transcript
