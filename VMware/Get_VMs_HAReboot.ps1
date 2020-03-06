# ***********************************************************************
# * Title:            Get list of VMs that rebooted due to HA event
# * Purpose:          This script will export a list of VMs that rebooted
# *                   due to an HA event
# * Args:             vCenter
# * Author:           Ryan Patel
# * Creation Date:    2/1/2018
# * Last Modified:    2/1/2018
# * Version:          1.0
# ***********************************************************************
#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\HAReboots\"
$FileName = $LogPath + "VMsRebootedDueToHA_" + $Datestamp + ".txt"

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

#Get list of VMs that rebooted due to HA event
$Date=Get-Date
$HAVMrestartold=5
Get-VIEvent -maxsamples 100000 -Start ($Date).AddDays(-$HAVMrestartold) -type warning | Where {$_.FullFormattedMessage -match "restarted"} |select CreatedTime,FullFormattedMessage |sort CreatedTime -Descending | FT -AutoSize

#Disconnecting from vCenter
Disconnect-viserver -Confirm:$false

Stop-Transcript
