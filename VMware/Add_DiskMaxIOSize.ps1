<#
SYNOPSIS
	Change DiskMaxIOSize due to XIO Storage
Description
	This script adds the Advanced Setting fix for Windows VMs on XIO.
.NOTES
    File Name		: Add_DiskMaxIOSize.ps1
    Author			: Ryan Patel
    Prerequisite	: Select Cluster
    Creation Date	: 12/17/2018
	Version			: 1.0
	Update Log:
#>
#define the log file
$datestamp = Get-date -Uformat %Y%m%d
$LogPath = "\\rp1rrinas01\platform\ScriptLogs\Storage\"
$fileName = $LogPath + $scluster + "_" + $datestamp + ".txt"

# Start Logging
$Timestart = Get-date
Start-Transcript $fileName

# Select a vcenter
Get-content vcenterList.txt

[int]$ivcenter = Read-Host "`nSelect a vcenter Number:"

$vcenter = (Get-content vcenterList.txt -Totalcount ($ivcenter+1))[-1]
$vcenter = $vcenter.substring(4)
$vcenter

If ($vcenter -eq 'End of List****') {
    Write-Host "Invalid Selection. Exiting."
    exit
}

Write-Host "`nYou Picked: "$vcenter `n 

# Connect to selected vCenter
Connect-VIServer $vcenter -Warningaction Silentlycontinue

# Select the Cluster
Write-Host ""
Write-Host "Choose the Cluster where we are adding the Advanced Settings:"
Write-Host ""
$iCluster = Get-cluster | Select Name | Sort Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster:"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"."
$sHosts = Get-Cluster $sCluster | Get-VMHost

ForEach ($sHost in $sHosts){
Get-VMHost | Get-AdvancedSetting -Name 'Disk.DiskMaxIOSize' | Set-AdvancedSetting -Value "4096" -Confirm:$false
}

# Disconnect from vcenter
Disconnect-VIServer $vcenter -confirm:$false

Stop-Transcript