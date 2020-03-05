# *******************************************************************
# * Title:            Storage Path(s) Reporting      
# * Purpose:          This script creates & report of the Active, Standby
# *                   and Dead Paths.
# * Author:           Ryan Patel
# * Creation Date:    03/13/2018
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

# Select the Cluster
Write-Host ""
Write-Host "Choose which Cluster to scan:"
Write-Host ""
$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster:"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"."

$VMHosts = Get-Cluster $sCluster | Get-VMHost  | ? { $_.ConnectionState -ne "Disconnected" } | Sort-Object -Property Name
$results= @()
 
foreach ($VMHost in $VMHosts) {
[ARRAY]$HBAs = $VMHost | Get-VMHostHba -Type "FibreChannel"
 
    foreach ($HBA in $HBAs) {
    $pathState = $HBA | Get-ScsiLun | Get-ScsiLunPath | Group-Object -Property state
    $pathStateActive = $pathState | ? { $_.Name -eq "Active"}
    $pathStateDead = $pathState | ? { $_.Name -eq "Dead"}
    $pathStateStandby = $pathState | ? { $_.Name -eq "Standby"}
    $results += "{0},{1},{2},{3},{4},{5}" -f $VMHost.Name, $HBA.Device, $VMHost.Parent, [INT]$pathStateActive.Count, [INT]$pathStateDead.Count, [INT]$pathStateStandby.Count
    }
}

ConvertFrom-Csv -Header "VMHost","HBA","Cluster","Active","Dead","Standby" -InputObject $results | Ft -AutoSize

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false