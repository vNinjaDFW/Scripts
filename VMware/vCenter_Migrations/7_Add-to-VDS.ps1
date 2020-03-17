<#
SYNOPSIS
	Add Host to vDS
Description
	Add Host to new vDS
.NOTES
#>

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

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

$svds = Get-VDSwitch
$sCluster = Get-Folder Decommission
$sHosts = Get-VMHost -Location $sCluster

# Select the ESXi Mgmt PortGroup
Write-Host ""
Write-Host "Choose the ESXi Mgmt PortGroup:" -BackgroundColor Yellow -ForegroundColor Black
Write-Host ""
$iPG =  Get-VirtualSwitch -Name $svDS | Get-VirtualPortGroup | Select Name | Sort-object Name
$i = 1
$iPG | %{Write-Host $i":" $_.Name; $i++}
$dPG = Read-Host "Enter the number for the ESXi Mgmt PortGroup"
$sMPG = $iPG[$dPG -1].Name
Write-Host "You picked:" $sMPG"." -ForegroundColor Blue

# Select the vMotion PortGroup
Write-Host ""
Write-Host "Choose the vMotion PortGroup:" -BackgroundColor Yellow -ForegroundColor Black
Write-Host ""
$iPG =  Get-VirtualSwitch -Name $svDS | Get-VirtualPortGroup | Select Name | Sort-object Name
$i = 1
$iPG | %{Write-Host $i":" $_.Name; $i++}
$dPG = Read-Host "Enter the number for the vMotion PortGroup"
$svPG = $iPG[$dPG -1].Name
Write-Host "You picked:" $svPG"." -ForegroundColor Blue

foreach ($ESXHost in $sHosts) {
	# Add ESXi host to VDS
	Write-Host "Adding" $ESXHost "to" $svDS
	Add-VDSwitchVMHost -VDSwitch $svDS -VMHost $ESXHost | Out-Null

	# Migrate pNIC to VDS (vmnic5)
	Write-Host "Adding vmnic5 to" $svDS
	$ESXHostNetworkAdapter = Get-VMHost $ESXHost | Get-VMHostNetworkAdapter -Physical -Name vmnic5
	Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $svDS -VMHostNetworkAdapter $ESXHostNetworkAdapter -Confirm:$false

	# Migrate Mgmt from vSS to vDS
	$mPG = "Management Network"
	Write-Host "Migrating" $sMPG "to" $svDS
	$dvportgroup = Get-VDPortgroup -Name $sMPG -VDSwitch $svDS
	$vmk = Get-VMHostNetworkAdapter -Name vmk0 -VMHost $ESXHost
	Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -Confirm:$false | Out-Null

	# Migrate vMotion from vSS to vDS
	$mPG = "vMotion"
	Write-Host "Migrating" $svPG "to" $svDS
	$dvportgroup = Get-VDPortgroup -Name $svPG -VDSwitch $svDS
	$vmk = Get-VMHostNetworkAdapter -Name vmk1 -VMHost $ESXHost
	Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -Confirm:$false | Out-Null   
}

# Disconnect from vCenter
Disconnect-VIServer * -confirm:$false

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black
