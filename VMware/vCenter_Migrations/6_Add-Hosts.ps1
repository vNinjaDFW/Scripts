<#
SYNOPSIS
	Add ESXi Hosts to vCenter
Description
	This script will add new ESXi Hosts to the chosen vCenter.
.NOTES
    File Name		: Add-Hosts.ps1
    Author			: Ryan Patel
    Prerequisite	: vCenter, Hostname
    Creation Date	: 05/01/2018
	Last Modified	: 05/01/2018
	Version			: 1.0
	Update Log:
	05/01/2018:   	: Script created
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

#Decommission = Get-Folder Decommission
$rootpwd = Read-host -Prompt "Please enter local root password"

100..102 | Foreach-Object {Add-VMHost XXX -Location Decommission -User root -Password $rootpwd -RunAsync -force:$true}

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false
