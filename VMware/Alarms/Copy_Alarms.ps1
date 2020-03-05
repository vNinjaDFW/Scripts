# *******************************************************************
# * Title:            Copy vCenter Alarms
# * Purpose:          This script copies vCenter Alarms from one
# * Args:             vCenter to another vCenter
# * Author:           Ryan Patel
# * Creation Date:    03/09/2018
# * Last Modified:    03/09/2018
# * Version:          1.0
# *******************************************************************
$svCenter = Read-Host "Which vCenter would you like to copy from?"
$dvCenter = Read-Host "Which vCenter would you like to copy to?"
$vis = @($svCenter, $dvCenter)

Connect-VIServer $vis -WarningAction:SilentlyContinue

Set-Variable -Name alarmLength -Value 80 -Option "constant"
Get-Datacenter -Server $svCenter | Select Name
$fromdc = Read-Host "Which Datacenter would you like to copy alarms FROM?"
Get-Datacenter -Server $dvCenter | Select Name
$todc = Read-Host "Which Datacenter would you like to copy alarms TO?"
$from = Get-Datacenter -Name $fromdc -Server $svCenter | Get-View
$to1 = Get-Datacenter -Name $todc -Server $dvCenter | Get-View
 
function Move-Alarm{
  param($Alarm, $From, $To, [switch]$DeleteOriginal = $false)
  $alarmObj = Get-View $Alarm -Server $svCenter
  $alarmMgr = Get-View AlarmManager -Server $dvCenter
 
  if($deleteOriginal){
    #$alarmObj.RemoveAlarm()
  }
  $newAlarm = New-Object VMware.Vim.AlarmSpec
  $newAlarm = $alarmObj.Info
  $oldName = $alarmObj.Info.Name
  $oldDescription = $alarmObj.Info.Description
 
  foreach($destination in $To){
    $newAlarm.Expression.Expression | %{
      if($_.GetType().Name -eq "EventAlarmExpression"){
         $needsChange = $true
      }
    }
 
    $alarmMgr.CreateAlarm($destination.MoRef,$newAlarm)
    $newAlarm.Name = $oldName
    $newAlarm.Description = $oldDescription
  }
}
 
$alarmMgr = Get-View AlarmManager -Server $svCenter
 
$alarms = $alarmMgr.GetAlarm($from.MoRef)
$alarms | % {
  Move-Alarm -Alarm $_ -From (Get-View $_) -To $to1 -DeleteOriginal:$false
}