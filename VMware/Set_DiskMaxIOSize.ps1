<#
SYNOPSIS
	ESXi EFI firmware fix for XIO
Description
	https://kb.vmware.com/s/article/2137402
.NOTES
    File Name		: Set_DisMaxIOSize.ps1
    Author			: Ryan Patel
    Prerequisite	: vCenter, Cluster
    Creation Date	: 01/09/2019
	Version			: 1.0
	Update Log:
#>

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\HostBuild\"
$FileName = $LogPath + "DiskMaxIOSizeChange_" + $Datestamp + ".txt"

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

# Select the Cluster
Write-Host ""
Write-Host "Choose the Cluster:"
Write-Host ""
$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster:"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"."

# Set the ESXi DiskMaxIOSize parameter
$scope = Get-Cluster $sCluster | Get-VMHost *
ForEach ($esx in $scope){
Get-VMHost $esx | Get-AdvancedSetting -Name 'Disk.DiskMaxIOSize' | Set-AdvancedSetting -Value "4096" -Confirm:$false
}

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false

Stop-Transcript
