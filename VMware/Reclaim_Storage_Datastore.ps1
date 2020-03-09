# *******************************************************************
# * Title:            ESXi Storage Reclaim Script for specified Datastore
# * Purpose:          This script will reclaim unused space for the array
# * 				  for the specified Datastore.
# * Args:             Hostname & Datastore
# * Author:           Ryan Patel
# * Creation Date:    08/09/2017
# * Last Modified:    10/16/2017
# * Version:          1.0
# *******************************************************************
# Enter the name of the Cluster
[string]$sCluster = (Read-Host "Please enter the name of the Cluster:")

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\Storage\"
$FileName = $LogPath + $sCluster + "_Reclaim_" + $Datestamp + ".txt"

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

# Select the Datastore
Write-Host ""
Write-Host "Choose the Datastore to reclaim space on:"
#Write-Host "(it may take a few seconds to build the list)"
Write-Host ""
$iDatastore = Get-Cluster $sCluster | Get-Datastore | Select Name | Sort-object Name
$i = 1
$iDatastore | %{Write-Host $i":" $_.Name; $i++}
$dDatastore = Read-Host "Enter the number for the Datastore:"
$sDatastore = $iDatastore[$dDatastore -1].Name
Write-Host "You picked:" $sDatastore"."

# Select the Host in the specified Cluster
Write-Host ""
Write-Host "Choose which Host to run this Script from:"
Write-Host ""
$iHost = Get-Cluster $sCluster | Get-VMHost | Select Name | Sort-object Name
$i = 1
$iHost | %{Write-Host $i":" $_.Name; $i++}
$DHost = Read-Host "Enter the number for the Host:"
$sHost = $iHost[$DHost -1].Name
Write-Host "You picked:" $sHost

Set-PowerCLIConfiguration -WebOperationTimeoutSeconds -1 -Scope Session -Confirm:$false

# Start Storage Reclaim
Write-Host ""
Write-Host "----- Starting Storage Reclaim on:"$sDatastore "-----" -ForegroundColor Blue
Write-Host ""
 
$esxcli = Get-EsxCli -VMHost $sHost
$esxcli.storage.vmfs.unmap($null,"$sDatastore",$null)

Write-Host ""
Write-Host "----- Storage Reclaim has completed on:"$sDatastore "-----" -ForegroundColor Green
Write-Host ""

# Disconnect from vCenter
Disconnect-VIServer $vCenter -Confirm:$false

# Stop Logging
Stop-Transcript
