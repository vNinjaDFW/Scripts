# ***********************************************************************
# * Title:            Configure ESXi Host Scratch
# * Purpose:          This script configures the scratch config location 
# *                   for all hosts in a specified cluster and provides
# *                   list of hosts that need to be rebooted for change
# *                   to take affect
# * Args:             vCenter, Cluster, Datastore, Folder
# * Author:           Ryan Patel
# * Creation Date:    11/14/2017
# * Last Modified:    11/14/2017
# * Version:          1.0
# ***********************************************************************
#Enter the name of a Cluster
[string]$Cluster = (Read-Host "Please enter the name of the Cluster:")

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\rp1rrinas01\platform\ScriptLogs\Storage\"
$FileName = $LogPath + $Cluster + "_ScratchConfig_" + $Datestamp + ".txt"

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

# Connect to selected vCenter
Write-Host "Connecting to $vCenter..." -Foregroundcolor "Yellow" -NoNewLine
Connect-VIServer $vCenter -WarningAction SilentlyContinue

# Select the Datastore
Write-Host ""
Write-Host "Choose the Datastore:" -BackgroundColor Yellow -ForegroundColor Black
Write-Host ""
$iDStore =  Get-Datastore | Select Name | Sort-object Name
$i = 1
$iDStore | %{Write-Host $i":" $_.Name; $i++}
$dDStore = Read-Host "Enter the number for the Datastore"
$sDStore = $iDStore[$dDStore -1].Name
Write-Host "You picked:" $sDStore"." -ForegroundColor Blue

#Set Folder Name
[String]$Folder = "ESXi_Scratch_Dir"

#Function to use multiple colors in one command
function Write-Color([String[]]$Text, [ConsoleColor[]]$Color) {
    for ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    Write-Host
}

#Defining array variables
$vmhost_array = @()
$dir = @()
$reboot_servers = @()

#Getting the path of the script
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# Select the Cluster
Write-Host ""
Write-Host "Choose the Cluster where $sHost is going:" -BackgroundColor Yellow -ForegroundColor Black
Write-Host ""
$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster:"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"." -ForegroundColor Blue

#Getting the list of the ESXi hosts in the $Cluster
$vmhost_array = Get-Cluster $sCluster | Get-VMhost

#Set Syslog.global.logDir to [] /scratch/log and uncheck unique box
Foreach ($vmhost in $vmhost_array) {
   Get-AdvancedSetting -Entity (Get-vmhost $vmhost) -Name Syslog.global.logDir | set-advancedsetting -value "[] /scratch/log" -Confirm:$false
   Get-AdvancedSetting -Entity (Get-vmhost $vmhost) -Name Syslog.global.logDirUnique | set-advancedsetting -value False -Confirm:$false
}

#Getting Scratch datastore UUID
$ds_view = Get-View (Get-View (Get-VMHost -Name $vmhost_array[0]).ID).ConfigManager.StorageSystem
	foreach ($vol in $ds_view.FileSystemVolumeInfo.MountInfo) {
		if ($vol.Volume.Name -eq $sDStore) {
      $sDStore_uuid =  $vol.Volume.Uuid
    }
}

#Create and mount datastore to be used as a scratch location
New-PSDrive -Name "DS" -Root \ -PSProvider VimDatastore -Datastore (Get-VMHost -Name $vmhost_array[0] | Get-Datastore $sDStore) | out-null
New-Item -Path DS:\$folder -ItemType Directory
Set-Location DS:\$folder

#Collect the list of the folders
$dir = dir

#Check if the scratch folders exist for the ESXi hosts and create missing folders
Foreach ($vmhost in $vmhost_array) {
If ($dir.name -contains $vmhost.name){
  Continue
  }
else{
  Write-Color -Text "`n Creating scratch folder for ", $vmhost -Color Green,Red
  mkdir $vmhost | out-null
  }
}

#Check if the ESXi host is already configured with correct scratch location
Foreach ($vmhost in $vmhost_array){
	$row = '' | Select Server_Name
	$configured_scratch = (Get-VMhost $vmhost | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation").value
	$current_scratch = (Get-VMhost $vmhost | Get-AdvancedSetting -Name "ScratchConfig.CurrentScratchLocation").value
  $correct_scratch = "/vmfs/volumes/"+$sDStore_uuid+"/"+$folder+"/"+$vmhost
#	Write-Host "`n Correct scratch is" $correct_scratch
# Write-Host "`n Configured Scratch on" $vmhost "is" $configured_scratch
#	Write-Host "`n Current Scratch on" $vmhost "is" $current_scratch
  If (($configured_scratch -eq $correct_scratch) -and ($current_scratch -eq $correct_scratch)) {
    Write-Color -Text "`n ESXi host ", $vmhost, " was already configured with the correct scratch location" -Color Green,Red,Green
  } elseif($configured_scratch -eq $correct_scratch) {
	Write-Color -Text "`n The ESXi host", $vmhost, " was already configured correctly, `n but it hasn't been restared after the configuration change" -Color Yellow,Red,Yellow
	$row.Server_Name = $vmhost.Name
	$reboot_servers += $row
	} else {
    Get-VMhost $vmhost | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation" |Set-AdvancedSetting -Value $correct_scratch -Confirm:$false |out-null
    Write-Host -Fore:Red "`n ESXi host" $vmhost "is configured with the correct scratch location"
		$row.Server_Name = $vmhost.Name
		$reboot_servers += $row
  }
}

#Provide output with the list of ESXi servers to be rebooted for the configration change to take effect
Write-Host -Fore:Green "`n The configuration of the scratch location for ESXi servers in cluster" $cluster "is complete"
Write-Host -Fore:Green "`n The following ESXi hosts have to be rebooted for the configuration change to take effect:"
foreach ( $server in $reboot_servers ) {
Write-Host -Fore:Red `n $server.Server_Name
}

#Change location back to original
Set-Location $scriptPath

#Disconnecting from vCenter
Disconnect-viserver -Confirm:$false

Stop-Transcript