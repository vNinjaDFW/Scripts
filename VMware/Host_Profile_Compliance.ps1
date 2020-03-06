# *******************************************************************
# * Title:            Host Profile Compliance Report
# * Purpose:          This script creates a Compliance Report
# * 				  for Host Profiles.
# * Author:           Ryan Patel
# * Creation Date:    09/08/2017
# * Last Modified:    09/08/2017
# * Version:          1.0
# *******************************************************************
# Get the list of vCenters
$vCenters = Get-Content 'vCenters.csv'

foreach ($vCenter in $vCenters)
{
Connect-VIServer $vCenter -WarningAction SilentlyContinue

Get-VMHost | ForEach-Object{
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\Profile_Compliance\"
$csvfile = $LogPath + $vCenter + ".csv"
$HPDetails = @()
Foreach ($VMHost in Get-VMHost) {
   $HostProfile = $VMHost | Get-VMHostProfile
   if ($VMHost | Get-VMHostProfile) {
      $HP = $VMHost | Test-VMHostProfileCompliance
      If ($HP.ExtensionData.ComplianceStatus -eq "nonCompliant") {
         Foreach ($issue in ($HP.IncomplianceElementList)) {
            $Details = "" | Select VMHost, Compliance, HostProfile, IncomplianceDescription
            $Details.VMHost = $VMHost.Name
            $Details.Compliance = $HP.ExtensionData.ComplianceStatus
            $Details.HostProfile = $HP.VMHostProfile
            $Details.IncomplianceDescription = $Issue.Description
            $HPDetails += $Details
         }
      } Else {
         $Details = "" | Select VMHost, Compliance, HostProfile, IncomplianceDescription
         $Details.VMHost = $VMHost.Name
         $Details.Compliance = "Compliant"
         $Details.HostProfile = $HostProfile.Name
         $Details.IncomplianceDescription = ""
         $HPDetails += $Details
      }
   } Else {
      $Details = "" | Select VMHost, Compliance, HostProfile, IncomplianceDescription
      $Details.VMHost = $VMHost.Name
      $Details.Compliance = "No profile attached"
      $Details.HostProfile = ""
      $Details.IncomplianceDescription = ""
      $HPDetails += $Details
   }
}
$HPDetails | Export-CSV $csvfile -NoTypeInformation
}
Disconnect-VIServer $vCenter -confirm:$false
}

# Combine CSVs into one Excel Document
$finalfile = $LogPath + "Profile_Compliance" + "_" + $Datestamp + ".xlsx"
$tabs = @("Server01","Server02","Server69")
$Excel = New-Object -ComObject excel.application
$Excel.visible = $false
$workbook = $Excel.workbooks.add(1)
$tabs | %{
 $processes = Import-Csv -Path $LogPath\$_.csv
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

# Delete CSV Files
Remove-Item $LogPath -Include *.csv -Force -Recurse
