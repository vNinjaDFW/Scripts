# *******************************************************************
# * Title:            ESXi Storage Reclaim Script for Datastores
# * Purpose:          This script will reclaim unused space for the array
# * 				  for ALL Datastores connected to the specified Host.
# * Args:             Cluster Name
# * Author:           Ryan Patel
# * Creation Date:    08/09/2017
# * Last Modified:    08/09/2017
# * Version:          1.0
# *******************************************************************
# Enter the name of the Cluster
[string]$sCluster = (Read-Host "Please enter the name of the Cluster:")

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVERNAME\ScriptLogs\Storage\"
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

# Start Storage Reclaim
$esxcli = Get-EsxCli -VMHost $sHost
$DataStores = Get-Datastore -VMHost $sHost | Where-Object {$_.ExtensionData.Summary.Type -eq 'VMFS' -And $_.ExtensionData.Capability.PerFileThinProvisioningSupported} | Sort-Object Name
Set-PowerCLIConfiguration -WebOperationTimeoutSeconds -1 -Scope Session -Confirm:$false

ForEach ($DStore in $DataStores) {
    Write-Host ""
	Write-Host "----- Starting Storage Reclaim on:"$DStore "-----" -ForegroundColor Blue
	Write-Host ""
    $esxcli.storage.vmfs.unmap($null,$DStore,$null)
    Write-Host ""
	Write-Host "----- Storage Reclaim has completed on:"$DStore "-----" -ForegroundColor Green
	Write-Host ""
    Start-Sleep -s 10
}

# Disconnect from vCenter
Disconnect-VIServer $vCenter -Confirm:$false

# Stop Logging
Stop-Transcript
