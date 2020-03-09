<#
SYNOPSIS
	ESXi Product Locker Automation
Description
	This script configures ESXi Hosts to use a shared ProductLocker for Tools.
.NOTES
    File Name		: Set_ProductLocker.ps1
    Author			: Ryan Patel
    Prerequisite	: vCenter, Cluster, Datastore
    Creation Date	: 06/12/2018
	Version			: 1.0
	Update Log:
#>

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\Storage\"
$FileName = $LogPath + $Cluster + "_ProductLocker_" + $Datestamp + ".txt"

#Start Logging
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
Write-Host "Choose the Cluster we are working on:" -BackgroundColor Yellow -ForegroundColor Black
Write-Host ""
$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster:"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"." -ForegroundColor Blue

# Select the Datastore
Write-Host ""
Write-Host "Choose the Product Locker Datastore:" -BackgroundColor Yellow -ForegroundColor Black
Write-Host ""
$iDStore = Get-Cluster $sCluster | Get-Datastore | where {$_.ExtensionData.summary.MultipleHostAccess -eq "true"} | Select Name | Sort-object Name
$i = 1
$iDStore | %{Write-Host $i":" $_.Name; $i++}
$dDStore = Read-Host "Enter the number for the Product Locker Datastore:"
$sDStore = $iDStore[$dDStore -1].Name
Write-Host "You picked:" $sDStore"." -ForegroundColor Blue

# Create Folder Location
[String]$Folder = "productLocker"
New-PSDrive -Name "DS" -Root \ -PSProvider VimDatastore -Datastore (Get-Datastore $sDStore) | Out-Null
New-Item -Path DS:\$folder -ItemType Directory -Confirm:$false -ErrorAction Ignore
Set-Location DS:\$folder
Write-Host "Creating the Product Locker for $sCluster..." -ForegroundColor Blue

# Set Source Location
$VMTSource = "\\SERVER\VMware\VMwareTools"

# Copy Source to Product Locker Location
Set-Location $scriptPath
Copy-DatastoreItem -Item $VMTSource\* -Destination DS:\productLocker\ -Recurse

# Set the Product Locker Location
$sHosts = Get-Cluster $sCluster | Get-VMHost
foreach ($sHost in $sHosts) {
	$sHost | Get-AdvancedSetting -Name 'UserVars.ProductLockerLocation'| Set-AdvancedSetting -Value "/vmfs/volumes/$sDStore/productLocker" -confirm:$False
	}

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false

Stop-Transcript
