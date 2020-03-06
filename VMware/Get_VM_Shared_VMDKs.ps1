# *******************************************************************
# * Title:            Get VMs with shared VMDKs      
# * Purpose:          This script will get any VMs with shared VMDKs
# * Args:             vCenter & Cluster Name
# * Author:           Ryan Patel
# * Creation Date:    01/01/2018
# * Last Modified:    01/01/2018
# * Version:          1.0
# *******************************************************************
# Enter the NEW Cluster Name
$sCluster = Read-Host "Please enter the name of the Cluster:"

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

#Create the array
$array = @()
$vms = Get-Cluster $sCluster | Get-VM

#Loop for BusSharingMode
foreach ($vm in $vms)
{
$disks = $vm | Get-ScsiController | Where-Object {$_.BusSharingMode -eq 'Physical' -or $_.BusSharingMode -eq 'Virtual'}
foreach ($disk in $disks){
$REPORT = New-Object -TypeName PSObject
$REPORT | Add-Member -type NoteProperty -name Name -Value $vm.Name
$REPORT | Add-Member -type NoteProperty -name VMHost -Value $vm.Host
$REPORT | Add-Member -type NoteProperty -name Mode -Value $disk.BusSharingMode
$REPORT | Add-Member -type NoteProperty -name Type -Value "BusSharing"
$array += $REPORT
}
}

$array | out-gridview

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false
