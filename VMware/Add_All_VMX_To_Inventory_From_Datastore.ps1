# ***********************************************************************
# * Title:            Add all VMX (Virtual Machines) to Inventory from Datastore
# * Purpose:          This asks for the cluster name, vcenter, folder name and 
# *                   datastore name, then it searches for all the VMX files in 
# *                   that datastore and adds them to inventory
# * Args:             vCenter, Cluster, Datastore, Folder
# * Author:           Ryan Patel
# * Creation Date:    2/1/2018
# * Last Modified:    2/1/2018
# * Version:          1.0
# ***********************************************************************

#Enter the name of a Cluster
[string]$Cluster = (Read-Host "Please enter the name of the Cluster:")

#Enter the name of the datastore
[string]$Datastore = (Read-Host "Please enter the name of the Datastore to add new VMs from:")

#Enter the name of a Folder to store new VMs
[string]$VMFolder = (Read-Host "Please enter the name of the Folder to store the new VMs in:")

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\rp1rrinas01\platform\ScriptLogs\Storage\"
$FileName = $LogPath + $Datastore + "_AddNewVMs_" + $Datestamp + ".txt"

#Start Logging
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

#Getting the list of the ESXi hosts in the $Cluster
$vmhost_array = get-cluster -name $cluster | Get-VMhost

#Get list of hosts in cluster and select the first 
$ESXHost = Get-Cluster $Cluster | Get-VMHost | select -First 1
 
foreach($Datastore in $Datastore) {
# Searches for .VMX Files in datastore variable
$ds = Get-Datastore -Name $Datastore | %{Get-View $_.Id}
$SearchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
$SearchSpec.matchpattern = "*.vmx"
$dsBrowser = Get-View $ds.browser
$DatastorePath = "[" + $ds.Summary.Name + "]"
 
# Find all .VMX file paths in Datastore variable and filters out .snapshot
$SearchResult = $dsBrowser.SearchDatastoreSubFolders($DatastorePath, $SearchSpec) | where {$_.FolderPath -notmatch ".snapshot"} | %{$_.FolderPath + ($_.File | select Path).Path}
 
# Register all .VMX files with vCenter
foreach($VMXFile in $SearchResult) {
New-VM -VMFilePath $VMXFile -VMHost $ESXHost -Location $VMFolder -RunAsync
 }
}

#Disconnecting from vCenter
Disconnect-viserver -Confirm:$false

Stop-Transcript