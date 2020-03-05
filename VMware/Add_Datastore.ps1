<#
SYNOPSIS
	Add Datastore from CSV Input File
Description
	This script adds Datastores from the CSV Template file.
.NOTES
    File Name		: Add_Datastore.ps1
    Author			: Ryan Patel
    Prerequisite	: Cluster & CSV File
    Creation Date	: 07/14/2017
	Last Modified	: 10/03/2018
	Version			: 1.2
	Update Log:
	10/03/2018:	  Added code to use CSV file for Input
				  Added code for selecting VMFS 5 or VMFS 6
#>
# Enter the name of a Host
[string]$scluster = (Read-Host "Please enter the name of the cluster:")

#define the log file
$datestamp = Get-date -Uformat %Y%m%d
$LogPath = "\\rp1rrinas01\platform\ScriptLogs\Storage\"
$fileName = $LogPath + $scluster + "_" + $datestamp + ".txt"

# Start Logging
$Timestart = Get-date
Start-Transcript $fileName

# Select a vcenter
Get-content vcenterList.txt

[int]$ivcenter = Read-Host "`nSelect a vcenter Number:"

$vcenter = (Get-content vcenterList.txt -Totalcount ($ivcenter+1))[-1]
$vcenter = $vcenter.substring(4)
$vcenter

If ($vcenter -eq 'End of List****') {
    Write-Host "Invalid Selection. Exiting."
    exit
}

Write-Host "`nYou Picked: "$vcenter `n 

# Connect to selected vCenter
Connect-VIServer $vcenter -Warningaction Silentlycontinue

# Select a Host
Write-Host ""
Write-Host "Choose the Host where we are adding a datastore:"
Write-Host ""
$iHost = Get-cluster $scluster | Get-VMHost | Select Name
$i = 1
$iHost | %{Write-Host $i":" $_.Name; $i++}
$dHost = Read-Host "Enter the number for the Host:"
$sHost = $iHost[$dHost -1].Name
Write-Host "You picked:" $sHost"."
$shost = Get-VMHost $shost

# Select the CSV File
$sFile = Select-FileDialog -Title "Select the CSV Source File" -Directory (Get-Location) -Filter "CSV Files (*.csv)|*.csv"
$iFile = Import-CSV $sFile

# Select VMFS5 or VMFS6
Write-Host "1. VMFS 5"
Write-Host "2. VMFS 6"

$iHostType = Read-Host "Select the VMFS Version:"

if ($iHostType -eq 1){
foreach ($row in $iFile) {
New-Datastore -VMHost $shost -Name $row.Datastore_Name -Path $row.Naa_Id -vmfs
}} elseif ($iHostType -eq 2){
foreach ($row in $iFile) {
New-Datastore -VMHost $shost -Name $row.Datastore_Name -Path $row.Naa_Id -vmfs -FileSystemVersion 6
}}

# Scan the cluster
Get-cluster $sCluster | Get-VMHost | Get-VMHostStorage -RescanallHba -RescanVMfS

# Disconnect from vcenter
Disconnect-VIServer $vcenter -confirm:$false

Stop-Transcript