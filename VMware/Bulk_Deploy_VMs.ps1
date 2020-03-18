<#
SYNOPSIS
Bulk deploy VMs from Template
Description
This script can deploy # of VMs from a Template that you 
specify.
.NOTES
File Name : Bulk_Deploy_VMs.ps1
Author : Ryan Patel
Prerequisite: Arguments will be prompted
Creation Date: 1/6/2020
Version :1.0
Update Log:
#>

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

# Number of VMs to deploy
$vm_count = "20"

# Select Template
Write-Host "Choose the Template:" -BackgroundColor Yellow -ForegroundColor Black
$iTemplate = Get-Template -Location MSE_Active_Templates | Select Name | Sort-object Name
$i = 1
$iTemplate | %{Write-Host $i":" $_.Name; $i++}
$dTemplate = Read-Host "Enter the number for the Template ( 1 -" $iTemplate.Count ")"
$sTemplate = $iTemplate[$dTemplate -1].Name
Write-Host "You picked:" $sTemplate"" -ForegroundColor Red

# Select the Cluster
Write-Host "Choose the Cluster:" -BackgroundColor Yellow -ForegroundColor Black
$iCluster = Get-Cluster | select Name | Sort-Object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster ( 1 -" $iCluster.Count ")"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"" -ForegroundColor Red

# Store the Datastore Objects
$sStore = Get-Cluster $sCluster | Get-Datastore | where {$_.Type -eq 'VMFS' -and $_.State -eq 'Available'} | Get-Random

# Select Folder Location
Write-Host "Select the VM's Folder Location..." -BackgroundColor Yellow -ForegroundColor Black
$i = 1
$folder | %{write-host $i":" $_.Name; $i++}
$sIndex = Read-Host "Select a Folder. Enter a number ( 1 -" $folder.Count ")"
$sFolder = $folder[$SIndex - 1].Name
Write-Host "You Picked folder:" $sFolder"" -ForegroundColor Red
Write-Host ""

# Specify the VM prefix name
$vm_prefix = "PREFIX-"

1..$vm_count | foreach {
$y="{0:D1}" -f + $_
$VM_name= $VM_prefix + $y
$sHost = Get-Cluster $sCluster | Get-VMHost | where {$_.ConnectionState -eq 'Connected'} | Get-Random
Write-Host "Deplying VM $VM_name..." -Foreground Green
New-VM -Name $VM_Name -VM $sTemplate -VMHost $sHost -Datastore $sStore -Location $sFolder -RunAsync
}

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$False
