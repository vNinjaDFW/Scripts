<#
SYNOPSIS
Evacuate an entire cluster (Compute Only)
Description
This script automates the Compute evacuation of an entire Cluster.
.NOTES
    File Name : EvacuateCluster_ComputeOnly.ps1
    Author : Ryan Patel
    Prerequisite : Prompts for VM Name and some selections
    Creation Date : 02/26/2020
 Version : 1.0
 Update Log:
#>
#Define the log file
$username = [Environment]::UserName
$scriptName = $MyInvocation.MyCommand.Name
$Datestamp = Get-Date -Uformat %Y%m%d%H%M%p
$LogPath = "\\SERVER\Scripts\Logging\"
$LogFile = $LogPath + $scriptName + $Datestamp + ".log"

# Start Logging
$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()
Start-Transcript $LogFile
Write-Host "$scriptName is being executed by $username"

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

# Select the Source Cluster
Write-Host "Choose the Source Cluster:" -BackgroundColor Yellow -ForegroundColor Black
$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Source Cluster ( 1 -" $iCluster.Count ")"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"" -ForegroundColor Red

# Select the Destination Cluster
Write-Host "Choose the Destination Cluster:" -BackgroundColor Yellow -ForegroundColor Black
#$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Destination Cluster ( 1 -" $iCluster.Count ")"
$sDCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sDCluster"" -ForegroundColor Red

# Export DRS Rules in Source Cluster
$drsExport = "DRSRules_" + $sCluster + ".xml"
Write-Host "Exporting DRS Rules for $sCluster"
Get-Cluster $sCluster | Get-DrsRule | Export-CliXml $drsExport

# Disable DRS on both Clusters
Write-Host "Disabling DRS on $sCluster"
Set-Cluster $sCluster -DrsEnabled:$false -Confirm:$false
Write-Host "Disabling DRS on $sDCluster"
Set-Cluster $sDCluster -DrsEnabled:$false -Confirm:$false

# Getting the list of VMs in Source Cluster
Write-Host "Getting the list of Powered On VMs...Standby"
$vmNames = Get-Cluster $sCluster | Get-VM | Where-Object {$_.Powerstate -eq 'PoweredOn'} | Select-Object Name
Write-Host "Exporting the list to CSV...Standby"
$vmNames | Export-CSV ./$sCluster.csv -NoTypeInformation

# Shutdown & Migrate VMs in Source Cluster
foreach ($vmName in $vmNames){
Write-Host "Shutting down $vmName"
Get-VM $vmName.Name | Shutdown-VMGuest -Confirm:$False
$dHosts = Get-Cluster $sDCluster | Get-VMHost | Get-Random
Write-Host "Migrating $vmName"
Move-VM $vmName.Name -Destination $dHosts -vMotionPriority High -Confirm:$false -RunAsync
Write-Host "$vmName has been migrated"
}

# Enable DRS on Destination Cluster
Write-Host "Enabling DRS on $sDCluster"
Set-Cluster $sDCluster -DrsEnabled:$true -Confirm:$false

# Import DRS Rules
ForEach ($rule in (Import-CliXml ("DRSRules_" + $sCluster + ".xml"))){
    New-DrsRule -Cluster (Get-Cluster $sDCluster) -Name $rule.Name -Enabled $rule.Enabled -KeepTogether $rule.KeepTogether -VM (Get-VM -Id $rule.VmIds)
}

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$False

Stop-Transcript
