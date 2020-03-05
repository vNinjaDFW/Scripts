# *******************************************************************
# * Title:            Get ESXi HW Model per Cluster
# * Purpose:          This script will get the Hardware Model, CPU
# *                   and Memory per Cluster.
# * Args:             Select the vCenter
# * Author:           Ryan Patel
# * Creation Date:    11/30/2017
# * Last Modified:    11/30/2017
# * Version:          1.0
# *******************************************************************
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

#Define the output
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\Hardware_Type\"
$FileName = $LogPath + $vCenter + "_" + $Datestamp + ".csv"

Get-VMHost |Sort Name |Get-View | Select Name, @{N='Type';E={$_.Hardware.SystemInfo.Vendor+ ' ' + $_.Hardware.SystemInfo.Model}}, @{N="Cluster";E={Get-Cluster -VMHost $_.Name}}, @{N='CPU';E={'PROC:' + $_.Hardware.CpuInfo.NumCpuPackages + ' CORES:' + $_.Hardware.CpuInfo.NumCpuCores + ' MHZ: ' + [math]::round($_.Hardware.CpuInfo.Hz / 1000000, 0)}}, @{N='MEM';E={'' + [math]::round($_.Hardware.MemorySize / 1GB, 0) + ' GB'}} | Export-CSV $FileName -NoTypeInformation

Invoke-Item $FileName

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false