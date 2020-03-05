# *******************************************************************
# * Title:            ScratchConfig & Logdir Locations
# * Purpose:          This script will get the ScratchConfig & Logdir
# * 				  locations for all Hosts in the selected Cluster.
# * Author:           Ryan Patel
# * Creation Date:    09/27/2017
# * Last Modified:    10/05/2017 
# * Version:          1.0
# *******************************************************************
[string]$LogPath = "\\SERVER\ScriptLogs\Scratch_Syslog\"
$FileName = $LogPath + $sCluster + "_" + $Datestamp + ".txt"

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
Write-Host "Choose the Cluster to scan:"
Write-Host ""
$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster:"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"."

$vmhosts = Get-Cluster $sCluster | Get-VMHost | Where-Object {$_.ConnectionState -ne "Not Responding"}

$output = foreach($vmhost in $vmhosts){
Get-AdvancedSetting $vmhost -Name "Syslog.global.logDir" | select Entity, Name, Value
Get-VMhost $vmhost | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation" | select Entity, Name, Value
}
$output | Export-CSV -NoTypeInformation $FileName -Force

Invoke-Item $FileName

Disconnect-VIServer $vCenter -confirm:$false