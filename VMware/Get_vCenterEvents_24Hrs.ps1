# *******************************************************************
# * Title:            Get vCenter Events from yesterday      
# * Purpose:          This script gets vCenter Events from
# *                   yesterday.
# * Args:             vCenter                                                             
# * Author:           Ryan Patel
# * Creation Date:    07/26/2017
# * Last Modified:    08/01/2017
# * Version:          2.0
# *******************************************************************
#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\vCenterEvents\"
$FileName = $LogPath + "Logs\" + "vCenter_Alarms" + "_" + $Datestamp + ".txt"

# Start Logging
$Timestart = Get-Date
Start-Transcript $FileName

# Get the list of vCenters
$vCenters = Get-Content "$LogPath\vCenters.csv"

foreach ($vCenter in $vCenters)
{
Connect-VIServer $vCenter -WarningAction SilentlyContinue
Get-VIEvent -Types Error -Start ([datetime]::Today).AddDays(-1) -Finish ([datetime]::Today) | Select CreatedTime,UserName,FullFormattedMessage | Export-CSV -NoTypeInformation "$LogPath\Today\$vCenter.csv" -Force
Disconnect-VIServer $vCenter -Confirm:$false
}

# Combine CSVs into one Excel Document
$finalfile = $LogPath + "vCenter_Alarms" + "_" + $Datestamp + ".xlsx"
$tabs = @("SERVER", "SERVER2")
$Excel = New-Object -ComObject excel.application
$Excel.visible = $false
$workbook = $Excel.workbooks.add(1)
$tabs | %{
 $processes = Import-Csv -Path $LogPath\Today\$_.csv
 $worksheet = $workbook.WorkSheets.add()
 $processes | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation | Clip.exe
 $worksheet.select()
 $worksheet.Name = $_
 [void]$Excel.ActiveSheet.Range("A1:A1").Select()
 [void]$Excel.ActiveCell.PasteSpecial()
 [void]$worksheet.UsedRange.EntireColumn.AutoFit()
}

[void]$Excel.ActiveSheet.Range("A1:A1").Select()
$workbook.saveas($finalfile)
$Excel.Quit()
Remove-Variable -Name excel
[gc]::collect()
[gc]::WaitForPendingFinalizers()

# Stop Logging
Stop-Transcript
