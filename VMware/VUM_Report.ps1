$vCenters = Get-Content 'XXX.csv'
foreach ($vCenter in $vCenters){

Connect-VIServer $vCenter -WarningAction SilentlyContinue
$LogPath = "\\SERVER\ScriptLogs\VUM_Compliance\"
$xlXLS = 56
$xlsfile = $LogPath + $vCenter + ".csv"
$Excel = New-Object -ComObject Excel.Application
$Excel.visible = $True
$Excel = $Excel.Workbooks.Add()
$Sheet = $Excel.Worksheets.Item(1)
$Sheet.Cells.Item(1,1) = "Server"
$Sheet.Cells.Item(1,2) = "Release"
$Sheet.Cells.Item(1,3) = "Version"
$Sheet.Cells.Item(1,4) = "Build"
$Sheet.Cells.Item(1,5) = "Baseline"
$Sheet.Cells.Item(1,6) = "Status"
$intRow = 2
$WorkBook = $Sheet.UsedRange
$WorkBook.Interior.ColorIndex = 19
$WorkBook.Font.ColorIndex = 11
$WorkBook.Font.Bold = $True
$compliant = "Compliant"
$notcompliant = "Not Compliant"
$unknown = "Unknown Status"
$baseline = Get-PatchBaseline -Name '*Patches*' -WarningAction SilentlyContinue
$vmhosts = Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"}
foreach ($vmhost in $vmhosts) {
  $vmhostview = get-vmhost $vmhost | Get-view
  $compliance = $vmhosts | get-compliance -Baseline $baseline -Detailed
  $Sheet.Cells.Item($intRow, 1) = [String]$vmhost
  $Sheet.Cells.Item($intRow, 2) = $vmhostview.Config.Product.name
  $Sheet.Cells.Item($intRow, 3) = $vmhostview.Config.Product.version
  $Sheet.Cells.Item($intRow, 4) = $vmhostview.Config.Product.build
  $Sheet.Cells.Item($intRow, 5) = $compliance.baseline.name
  if($compliance.status -eq 0) {
    $Sheet.Cells.Item($intRow, 6) = [String]$compliant
    $Sheet.Cells.Item($intRow, 6).Interior.ColorIndex = 4
    $Sheet.Cells.Item($intRow, 1).Interior.ColorIndex = 4
  }
  elseif($compliance.status -eq 1) {
    $Sheet.Cells.Item($intRow, 6) = [String]$notcompliant
    $Sheet.Cells.Item($intRow, 6).Interior.ColorIndex = 3
    $Sheet.Cells.Item($intRow, 1).Interior.ColorIndex = 3
  }
  else {
    $Sheet.Cells.Item($intRow, 6) = [String]$unknown
    $Sheet.Cells.Item($intRow, 6).Interior.ColorIndex = 48
    $Sheet.Cells.Item($intRow, 1).Interior.ColorIndex = 48
  }
  $intRow++
}}
$WorkBook.EntireColumn.AutoFit()
sleep 5
$Sheet.SaveAs($xlsfile,$xlXLS)
Disconnect-VIServer $vCenter -confirm:$false
