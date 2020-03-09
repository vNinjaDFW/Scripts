<#
SYNOPSIS
	Copy Template to another vCenter
Description
	Convert Template to VM, Export VM to OVF, Convert VM to Template, Deploy OVF, Convert VM to Template
.NOTES
    File Name		: Copy_Template.ps1
    Author			: Ryan Patel
    Prerequisite	: vCenter, Cluster, Datastore
    Creation Date	: 08/31/2017
	Version			: 1.0
	Update Log:
#>
[string]$LogPath = "\\SERVER\ScriptLogs\Templates\"
$OVFPath = 'C:\Temp\'

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d%H%M%p
$FileName = $LogPath + "Template_Copy_" + $Datestamp + ".txt"

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

# Select the Datacenter
Write-Host ""
Write-Host "Choose the Source Datacenter:"
#Write-Host "(it may take a few seconds to build the list)"
Write-Host ""
$iDatacenter = Get-Datacenter | Select Name | Sort-object Name
$i = 1
$iDatacenter | %{Write-Host $i":" $_.Name; $i++}
$DDatacenter = Read-Host "Enter the number for the Datacenter Location:"
$SDatacenter = $iDatacenter[$DDatacenter -1].Name
Write-Host "You picked:" $SDatacenter"."

# Select the Template
Write-Host ""
Write-Host "Choose the Template to copy:"
#Write-Host "(it may take a few seconds to build the list)"
Write-Host ""
$iTemplate = Get-Datacenter $SDatacenter | Get-Template | Select Name | Sort Name
$i = 1
$iTemplate | %{Write-Host $i":" $_.Name; $i++}
$DTemplate = Read-Host "Enter the number for the Template:"
$STemplate = $iTemplate[$DTemplate -1].Name
Write-Host "You picked:" $STemplate"."

# Convert Template to VM
Set-Template $STemplate -ToVM -Confirm:$False

# Export VM to OVF
Export-VM -VM $STemplate -Destination $OVFPath -Format OVF

# Convert VM back to Template
Set-VM -VM $STemplate -ToTemplate -Confirm:$False

# Disconnect from the Source vCenter
Disconnect-VIServer * -Confirm:$false

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
Connect-VIServer $DVCenter -WarningAction SilentlyContinue

# Select the Datacenter
Write-Host ""
Write-Host "Choose the Destination Datacenter:"
#Write-Host "(it may take a few seconds to build the list)"
Write-Host ""
$iDatacenter = Get-Datacenter | Select Name | Sort-object Name
$i = 1
$iDatacenter | %{Write-Host $i":" $_.Name; $i++}
$DDatacenter = Read-Host "Enter the number for the Datacenter Location:"
$SDatacenter = $iDatacenter[$DDatacenter -1].Name
Write-Host "You picked:" $SDatacenter"."

# Select the Cluster
Write-Host ""
Write-Host "Select the Cluster to deploy the Template to:"
#Write-Host "(it may take a few seconds to build the list)"
Write-Host ""
$iCluster = Get-Datacenter $SDatacenter | Get-Cluster | Select Name | Sort Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$DCluster = Read-Host "Enter the number of the Cluster:"
$SCluster = $iCluster[$DCluster -1].Name
Write-Host "You picked:" $SCluster"."

# Get Random Host in the selected Cluster
$SVMHost = Get-Cluster $SCluster | Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"} | Get-Random

# Get Random Datastore on random Host
$SDstore = Get-Cluster $SCluster | Get-Datastore | Where {($_.ExtensionData.Summary.MultipleHostAccess -eq "True") -and ($_.FreeSpaceGB -gt "500")} | Get-Random

# Get Network Portgroup
Write-Host ""
Write-Host "Select the Network to deploy the Template to:"
#Write-Host "(it may take a few seconds to build the list)"
Write-Host ""
$iNetwork = Get-VDSwitch | Get-VDPortgroup | Select Name | Sort Name
$i = 1
$iNetwork | %{Write-Host $i":" $_.Name; $i++}
$DNetwork = Read-Host "Enter the number of the Network Portgroup:"
$SNetwork = $iNetwork[$DNetwork -1].Name
Write-Host "You picked:" $SNetwork"."

# OVF Configurations
$OVFFileExt = Get-Childitem $OVFPath -Recurse -Include *.ovf -name
$OVFSource = $OVFPath + $OVFFileExt
$OVFConfig = Get-OVFConfiguration $OVFSource
$OVFConfig.NetworkMapping.DEV_LINUX_CORE_APP_DvSwitch.Value=$SNetwork

# Deploy OVF
Import-vApp -Source $OVFSource -OVFConfiguration $OVFConfig -VMHost $SVMHost -Location $SCluster -Datastore $SDstore

# Move Template to Correct Folder
Move-VM -VM $STemplate -Destination IT_Templates -Confirm:$false

# Convert VM back to Template
Set-VM -VM $STemplate -ToTemplate -Confirm:$False

# Remove Template from C:\Temp
Get-ChildItem $OVFPath -Include * | Remove-Item -recurse -Force

# Disconnect from the Source vCenter
Disconnect-VIServer * -Confirm:$false

Stop-Transcript
