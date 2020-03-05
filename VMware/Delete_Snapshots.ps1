# ***********************************************************************
# * Title:            Delete_Snapshots
# * Purpose:          This script will import list of VMs from a CSV file then
# *                   delete all their snapshots
# * Args:             CSV file, vCenter
# * Author:           Ryan Patel
# * Creation Date:    4/11/2018
# * Last Modified:    4/11/2018
# * Version:          1.0
# ***********************************************************************
#Define CSV file of the VM's to have their snapshots deleted and read them into a variable
[string]$csvfile = (Read-Host "Please enter the path to the CSV file") 
$vms = Import-Csv $csvfile

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

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER_NAME\ScriptLogs\Snapshots\"
$FileName = $LogPath + "DeleteSnapshots_" + $vCenter + "_" + $csvfile + "_" + $Datestamp + ".txt"

#Start Logging
$Timestart = Get-Date
Start-Transcript $FileName

#Connect to selected vCenter
Connect-VIServer $vCenter -Warningaction SilentlyContinue

#Remove Snapshots fore each VM in the CSV
foreach ($vm in $vms) { 
$vm = get-VM $vm.VM #Load the virtual machine object
$snapshotcount = $vm | Get-Snapshot | measure #Get the number of snapshots for the VM
$snapshotcount = $snapshotcount.Count #This line makes it easier to insert the number of snapshots into the log file
$timestamp = Get-Date #Get the current date/time and place entry into log that the script is going to remove x number of shapshots for the VM
Write-Host "`n$timestamp Removing $snapshotcount Snapshot(s) for VM $vm" #Display the number of snapshots being removed from the VM sna the time it started
$vm | Get-Snapshot | Remove-Snapshot -confirm:$false #Removes the VM's snapshot(s)
}

$timestamp = Get-Date 
Write-Host "`n$timestamp ***** Script Has Completed *****"

#Disconnecting from vCenter
Disconnect-viserver -Confirm:$false

Stop-Transcript