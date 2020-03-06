# *******************************************************************
# * Title:            Match VM Disk to Windows Disk
# * Purpose:          This script matches the Disk inside Windows
# *                   to the VMDK.
# * Args:             vCenter & VM
# * Author:           Ryan Patel
# * Creation Date:    11/17/2017
# * Last Modified:    11/17/2017
# * Version:          1.0
# *
# *******************************************************************
# Store the VM name
$vmName = (Read-Host "Please enter the name of the Windows VM:")

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

$cred = if ($cred){$cred}else{Get-Credential}  
$win32DiskDrive  = Get-WmiObject -Class Win32_DiskDrive -ComputerName $vmName -Credential $cred  
$vmHardDisks = Get-VM -Name $vmName | Get-HardDisk  
$vmDatacenterView = Get-VM -Name $vmName | Get-Datacenter | Get-View  
$virtualDiskManager = Get-View -Id VirtualDiskManager-virtualDiskManager  
foreach ($disk in $win32DiskDrive)  
{  
  $disk | Add-Member -MemberType NoteProperty -Name AltSerialNumber -Value $null  
  $diskSerialNumber = $disk.SerialNumber  
  if ($disk.Model -notmatch 'VMware Virtual disk SCSI Disk Device')  
  {  
    if ($diskSerialNumber -match '^\S{12}$'){$diskSerialNumber = ($diskSerialNumber | foreach {[byte[]]$bytes = $_.ToCharArray(); $bytes | foreach {$_.ToString('x2')} }  ) -join ''}  
    $disk.AltSerialNumber = $diskSerialNumber  
  }  
}  
$results = @()  
foreach ($vmHardDisk in $vmHardDisks)  
{  
  $vmHardDiskUuid = $virtualDiskManager.queryvirtualdiskuuid($vmHardDisk.Filename, $vmDatacenterView.MoRef) | foreach {$_.replace(' ','').replace('-','')}  
  $windowsDisk = $win32DiskDrive | where {$_.SerialNumber -eq $vmHardDiskUuid}  
  if (-not $windowsDisk){$windowsDisk = $win32DiskDrive | where {$_.AltSerialNumber -eq $vmHardDisk.ScsiCanonicalName.substring(12,24)}}  
  $result = "" | select vmName,vmHardDiskDatastore,vmHardDiskVmdk,vmHardDiskName,windowsDiskIndex,windowsDiskSerialNumber,vmHardDiskUuid,windowsDiskAltSerialNumber,vmHardDiskScsiCanonicalName  
  $result.vmName = $vmName.toupper()  
  $result.vmHardDiskDatastore = $vmHardDisk.filename.split(']')[0].split('[')[1]  
  $result.vmHardDiskVmdk = $vmHardDisk.filename.split(']')[1].trim()  
  $result.vmHardDiskName = $vmHardDisk.Name  
  $result.windowsDiskIndex = if ($windowsDisk){$windowsDisk.Index}else{"FAILED TO MATCH"}  
  $result.windowsDiskSerialNumber = if ($windowsDisk){$windowsDisk.SerialNumber}else{"FAILED TO MATCH"}  
  $result.vmHardDiskUuid = $vmHardDiskUuid  
  $result.windowsDiskAltSerialNumber = if ($windowsDisk){$windowsDisk.AltSerialNumber}else{"FAILED TO MATCH"}  
  $result.vmHardDiskScsiCanonicalName = $vmHardDisk.ScsiCanonicalName  
  $results += $result  
}  
$results = $results | sort {[int]$_.vmHardDiskName.split(' ')[2]}  
$results | FT -AutoSize


# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false

Stop-Transcript
