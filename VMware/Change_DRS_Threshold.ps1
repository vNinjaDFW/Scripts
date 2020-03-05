<#
SYNOPSIS
	Change DRS Threshold
Description
	Script will change DRS thresholds for the Cluster selected.
.NOTES
    File Name		: Change_DRS_Threshold.ps1
    Author			: Ryan Patel
    Prerequisite	: vCenter
    Creation Date	: 03/26/2018
	Last Modified	: 03/26/2018
	Version			: 1.0
#>
[string]$LogPath = "\\rp1rrinas01\platform\ScriptLogs\Storage\"

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

# Select the Cluster
Write-Host ""
Write-Host "Choose the Cluster where $sHost is going:" -BackgroundColor Yellow -ForegroundColor Black
Write-Host ""
$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster:"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"." -ForegroundColor Blue

# Select and Set the DRS Threshold
$rate = Read-Host "Enter a number from 1 to 5 for the level:"
$clus = Get-Cluster -Name $sCluster | Get-View
$clusSpec = New-Object VMware.Vim.ClusterConfigSpecEx
$clusSpec.drsConfig = New-Object VMware.Vim.ClusterDrsConfigInfo
$clusSPec.drsConfig.vmotionRate = $rate
$clus.ReconfigureComputeResource_Task($clusSpec, $true)

Stop-Transcript