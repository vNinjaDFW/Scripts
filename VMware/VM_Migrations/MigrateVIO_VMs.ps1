<#
SYNOPSIS
VM Migration from VIO
Description
This script helps in the migration of VIO VMs to native VMware.
.NOTES
File Name : MigrateVIO_VMs.ps1
Author : Ryan Patel
Prerequisite : Prompts for VM Name only
Creation Date : 10/17/19
Last Modified Date : 11/4/19
Version : 1.2
Update Log:
11/04/19: Reduced code to reflect Shutdown, Clone, NIC & Power On Only
12/17/19: Added code for CPU\Memory Hot-Add
12/18/19: Added code to clear VM Mac Conflict Alarm
12/20/19: Added code to disconnect cdrom
#>
#Define the log file
$username = [Environment]::UserName
$scriptName = $MyInvocation.MyCommand.Name
$Datestamp = Get-Date -Uformat %Y%m%d%H%M%p
$LogPath = ".\Scripts\Logging\"
$LogFile = $LogPath + $scriptName + $Datestamp + ".log"

# Start Logging
$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()
Start-Transcript $LogFile
Write-Host "$scriptName is being executed by $username"

# Welcome Screen
Clear
Write-Host "*********************************************"
Write-Host "| Welcome to the VIO Migration Tool |"
Write-Host "*********************************************"

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

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

# Store VM Name
$vIOVM = Read-Host "Enter the VIO VM's Name before parenthesis symbol in lowercase:" -OutVariable vioVM
$svVM = Get-VM $vIOVM* -Location (Get-Folder -Type VM OpenStack) | where {$_.Name -notlike "*root*"}

# Get Mac Addresses
Get-NetworkAdapter -VM $svVM | select NetworkName, MacAddress
Read-Host "Press <ENTER> when ready to Shutdown $newVM"

# Shutdown VIO VM
Write-Host "Shutting down $svVM. Standby..."
Stop-VM -VM $svVM -Confirm:$false -Verbose

If ($vCenter -eq 'XXX'){
$sFolder = Get-Folder -Type VM | where {$_.Name -eq "PRD_LNX_NJ"} | sort Name
} Elseif ($vCenter -eq 'XXX') {
$sFolder = Get-Folder -Type VM | where {$_.Name -eq "PRD_LNX_OB"} | sort Name
} Elseif ($vCenter -eq 'XXX') {
$sFolder = Get-Folder -Type VM | where {$_.Name -eq "DEV_LNX_NJ"} | sort Name
} Elseif ($vCenter -eq 'XXX') {
$sFolder = Get-Folder -Type VM | where {$_.Name -eq "DEV_LNX_OB"} | sort Name
}

# Clone the VM
$newVM = $vIOVM
$sHost = (Get-VM $svVM).VMHost
$sStore = Get-Datastore -VMHost $sHost | where {$_.Name -like '*DATA*' -and $_.Type -eq 'VMFS' -and $_.State -eq 'Available'} | Sort-Object -Property FreeSpaceGB -Descending | Select -First 1
Write-Host "Cloning $svVM as $newVM..."
New-VM -Name $newVM -VM $svVM -Datastore $sStore -VMHost $sHost -DiskStorageFormat EagerZeroedThick -Location $sFolder -Verbose

# Disable VIO VM NIC
Write-Host "Disabling VIO VM's NIC.."
Get-VM $svVM | Get-NetworkAdapter | Set-NetworkAdapter -StartConnected:$False -Confirm:$False -Verbose

# Get Network Adapter Settings
Write-Host "Getting Network Adapter 1..."
[string]$nAdapter1 = Get-VM $newVM | Get-NetworkAdapter -Name "Network adapter 1" | select NetworkName
$newAdapter1 = $nAdapter1 -replace ".*=" -replace "-.*"
Write-Host "Getting Network Adapter 2..."
[string]$nAdapter2 = Get-VM $newVM | Get-NetworkAdapter -Name "Network adapter 2" | select NetworkName
$newAdapter2 = $nAdapter2 -replace ".*=" -replace "-.*"

# Set Network Adapter Portgroups
Write-Host "Changing the vLAN for Network Adapter 1"
Get-VM $newVM | Get-NetworkAdapter -Name "Network adapter 1" | Set-NetworkAdapter -NetworkName $newAdapter1 -Confirm:$False -Verbose
Write-Host "Changing the vLAN for Network Adapter 2"
Get-VM $newVM | Get-NetworkAdapter -Name "Network adapter 2" | Set-NetworkAdapter -NetworkName $newAdapter2 -Confirm:$False -Verbose

# Enable CPU & Memory Hot-Add
Write-Host "Enabling CPU\Memory Hot-Add - $newVM..."
$nVM = Get-VM $newVM
$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec.memoryHotAddEnabled = $true
$spec.cpuHotAddEnabled = $true
$nVM.ExtensionData.ReconfigVM_Task($spec)

# Disable cdrom ISO
Get-VM $newVM | Get-CDDrive | Set-CDDrive -NoMedia -Confirm:$false

Read-Host "Press <ENTER> when ready to Power On $newVM"
Write-Host "Powering on the cloned VM - $newVM..."
Start-VM $newVM -Confirm:$False -Verbose
Write-Host "$newVM has been deployed" -ForegroundColor Green

Write-Host "Clearing Alarm on $newVM..."
Get-AlarmDefinition "VM MAC Conflict" | Set-AlarmDefinition -Enabled:$false
Get-AlarmDefinition "VM MAC Conflict" | Set-AlarmDefinition -Enabled:$true

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$False

Stop-Transcript
