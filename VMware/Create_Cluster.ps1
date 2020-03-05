# *******************************************************************
# * Title:            ESXi Server Build Configuration      
# * Purpose:          This script creates & configures a new
# *                   ESXi Cluster.
# * Args:             vCenter & Cluster Name
# * Author:           Ryan Patel
# * Creation Date:    07/18/2017
# * Last Modified:    08/07/2017
# * Version:          1.1
# *******************************************************************
[string]$LogPath = "\\rp1rrinas01\platform\ScriptLogs\ClusterBuild\"

# Enter the NEW Cluster Name
[string]$NEWCluster = Read-Host "Please enter the name of the NEW Cluster:"

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d%H%M%p
$FileName = $LogPath + $NEWCluster + "_" + $Datestamp + ".txt"

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

# Select the Datacenter
Write-Host ""
Write-Host "Choose which Datacenter to create the Cluster in:"
Write-Host ""
$iDatacenter = Get-Datacenter | Select Name | Sort-object Name
$i = 1
$iDatacenter | %{Write-Host $i":" $_.Name; $i++}
$DDatacenter = Read-Host "Enter the number for the Datacenter Location:"
$SDatacenter = $iDatacenter[$DDatacenter -1].Name
Write-Host "You picked:" $SDatacenter"."

# Create new Cluster
New-Cluster -Name $NewCluster -Location $SDatacenter -DrsAutomationLevel FullyAutomated -HAEnabled -HAAdmissionControlEnabled

Stop-Transcript