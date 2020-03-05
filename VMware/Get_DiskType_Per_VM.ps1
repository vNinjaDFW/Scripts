# *******************************************************************
# * Title:            Get Disk Type per VM
# * Purpose:          This script gets the Disk Type for
# *                   every VM specified in a Cluster.
# * Args:             vCenter, Cluster
# * Author:           Ryan Patel
# * Creation Date:    11/27/2017
# * Last Modified:    11/27/2017
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

$VMs = Get-VM *
$Data = @()
 foreach ($VM in $VMs){
	$VMDKs = $VM | get-HardDisk
	foreach ($VMDK in $VMDKs) {
		if ($VMDK -ne $null){
			$CapacityGB = $VMDK.CapacityKB/1024/1024
			$CapacityGB = [int]$CapacityGB
			$into = New-Object PSObject
			Add-Member -InputObject $into -MemberType NoteProperty -Name VMname $VM.Name
			Add-Member -InputObject $into -MemberType NoteProperty -Name Datastore $VMDK.FileName.Split(']')[0].TrimStart('[')
			Add-Member -InputObject $into -MemberType NoteProperty -Name VMDK $VMDK.FileName.Split(']')[1].TrimStart('[')
			Add-Member -InputObject $into -MemberType NoteProperty -Name StorageFormat $VMDK.StorageFormat
			Add-Member -InputObject $into -MemberType NoteProperty -Name CapacityGB $CapacityGB
			$Data += $into
		}
	}
}
$Data | Sort-Object VMname,Datastore,VMDK | Export-Csv -Path C:\Temp\$vCenter.csv -NoTypeInformation
Invoke-Item C:\Temp\$vCenter.csv

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false