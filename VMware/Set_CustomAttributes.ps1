# *******************************************************************
# * Title:            Update Custom Attributes      
# * Purpose:          This script updates CPU Type & Model for Hosts
# * Args:             vCenter & Cluster Name
# * Author:           Ryan Patel
# * Creation Date:    08/18/2017
# * Last Modified:    08/18/2017
# * Version:          1.0
# *******************************************************************
# Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\Attributes\"
$FileName = $LogPath + "Custom_Attributes" + "_" + $Datestamp + ".txt"

# Start Logging
$Timestart = Get-Date
Start-Transcript $FileName

# Get the list of vCenters
$vCenters = Get-Content 'vCenters.csv'

foreach ($vCenter in $vCenters)
{
Connect-VIServer $vCenter -WarningAction SilentlyContinue
# Set Attributes
Get-VMHost | ForEach-Object{
    Write-Host "Working on" $_
	$sCPU = Get-VMHost $_ | Select-Object -ExpandProperty ProcessorType
	$sModel = Get-VMHost $_ | Select-Object -ExpandProperty Model
	$sBuild = Get-VMHost $_ | Select-Object -ExpandProperty Build
	$cAttrib1 = "CPU Type"
	$cAttrib2 = "Model"
	$cAttrib3 = "Build"
	Set-Annotation -Entity $_ -CustomAttribute $cAttrib1 -Value $sCPU
	Set-Annotation -Entity $_ -CustomAttribute $cAttrib2 -Value $sModel
	Set-Annotation -Entity $_ -CustomAttribute $cAttrib3 -Value $sBuild
	Write-Host "Completed" $_
}
Disconnect-VIServer $vCenter -Confirm:$false
}

# Stop Logging
Stop-Transcript
