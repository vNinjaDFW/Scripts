# *******************************************************************
# * Title:            ESXi Host VIB Installation
# * Purpose:          This script installs VIBs on ESXi Hosts
# * Args:             vCenter & New Hostname                                                             
# * Author:           Ryan Patel
# * Creation Date:    08/15/2017
# * Last Modified:    08/15/2017
# * Version:          1.0
# *******************************************************************
# Enter the name of the Host
[string]$NEWHost = (Read-Host "Please enter the name of the Server:")

# Define VIB
[string]$VIBPATH = (Read-Host "Enter the Full Path to the VIB or Drag & Drop:")

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\HostBuild\"
$FileName = $LogPath + $NEWHost + "_" + $Datestamp + ".txt"

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

# Disable Alarm actions
$alarmMgr = Get-View AlarmManager 
$esx = Get-VMHost $NEWHost
$alarmMgr.EnableAlarmActions($esx.Extensiondata.MoRef,$false)

# Place Host in Maintenance Mode
Set-VMHost $NEWHost -state Maintenance

# Configuration Changes
Write-Host "Preparing $NEWHost for ESXCLI" -ForegroundColor Yellow
$ESXCLI = Get-EsxCli -VMHost $NEWHost

# Install VIBs
Write-Host "Installing VIB on $NEWHost" -ForegroundColor Yellow
$action = $ESXCLI.software.vib.install($null,$null,$null,$null,$null,$true,$null,$null,$VIBPATH)

# Verify VIB installed successfully
if ($action.Message -eq "Operation finished successfully.")
{Write-host "Action Completed successfully on $($_.Name)" -ForegroundColor Green}
else {Write-host $action.Message -ForegroundColor Red}
}

# Remove Host from Maintenance Mode
Set-VMHost $NEWHost -State Connected

# Enable Alarm actions
$alarmMgr.EnableAlarmActions($esx.Extensiondata.MoRef,$true)

Stop-Transcript
