<#
SYNOPSIS
Evacuate a cluster to different Compute & Storage
Description
This script automates the evacuation of an entire Cluster.
.NOTES
    File Name : MigrateVMs_FromCSV.ps1
    Author : Ryan Patel
    Prerequisite : Prompts for VM Name and some selections
    Creation Date : 02/26/2020
 Version : 1.0
 Update Log:
#>
$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

#Define CSV file of the VM's to be moved
[string]$csvfile = (Read-Host "What is the name of the CSV file:") 

# Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\VM_Migrations\"
$FileName = $LogPath + $Datestamp + "_" + $csvfile + ".txt"

# Start Logging
$Timestart = Get-Date
Start-Transcript $FileName

# Select a vCenter
Get-Content vCenterList.txt

[int]$ivCenter = Read-Host "`nSelect a vCenter Number:"

$vCenter = (Get-Content vCenterList.txt -TotalCount ($ivCenter+1))[-1]
$vCenter = $vCenter.substring(4)

If ($vCenter -eq 'End of List****') {
    Write-Host "Invalid Selection. Exiting."
    exit
}
 
Write-Host "`nYou Picked: "$vCenter `n
Start-sleep -s 3
 
# Connect to selected vCenter
Connect-VIServer $vCenter -WarningAction SilentlyContinue

# Import info from CSV file
$vmlist = IMport-csv $csvfile
foreach ($row in $vmlist){
   $svm = $row.VM
   $tgtCluster = $row.Cluster
   $tgtDatastore = $row.Datastore
   Get-VM $svm | Select-Object -Property Name | FT -AutoSize
          
   $vm = Get-VM -Name $svm
   $ds = Get-Datastore -Name $tgtDatastore
   $esx = Get-Cluster -Name $tgtCluster | Get-VMHost | Get-Random 
   $rp = Get-ResourcePool -Location $tgtCluster

   $spec = New-Object VMware.Vim.VirtualMachineRelocateSpec
   $spec.Datastore = $ds.ExtensionData.MoRef
   $spec.Host = $esx.ExtensionData.MoRef
   $spec.Pool = $rp.ExtensionData.MoRef
   $vm.ExtensionData.RelocateVM($spec,"defaultPriority")

}

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false

Stop-Transcript
