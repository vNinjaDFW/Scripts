# *******************************************************************
# * Title:            Get Disk Usage for All VMs
# * Purpose:          This script gets the VMs Disk Capacity & Free
# *                   Space. Edit the CSV manually to calculate Used
# * Args:             vCenter
# * Author:           Ryan Patel
# * Creation Date:    11/03/2017
# * Last Modified:    11/03/2017
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

$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\Storage\"
$FileName = $LogPath + $vCenter + "_Disk_Usage_" + $Datestamp + ".csv"

# Create CSV
$Report = @()

Get-Cluster Dev_App_01 | Get-VM | %{
  $ReportRow = "" | Select-Object VMName,DiskCapacity,DiskFreespace
  $ReportRow.VMName = $_.Name
  $ReportRow.DiskCapacity = $_.Guest.Disks | Measure-Object CapacityGB -Sum | Select -ExpandProperty Sum
  $ReportRow.DiskFreespace = $ReportRow.DiskCapacity - ($_.Guest.Disks | Measure-Object FreeSpaceGB -Sum | Select -ExpandProperty Sum)
  $Report += $ReportRow
}

$Report | Export-CSV $FileName -NoTypeInformation
Invoke-Item $FileName

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false
