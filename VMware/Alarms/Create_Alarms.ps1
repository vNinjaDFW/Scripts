$vcenterservers = "XXX"
$vcenterusername = 'XXX'
$vcenteruserpwd = 'XXX'
$alarmfile = import-csv .\vsphere65-alarms.csv
$AlertEmailRecipients = @("EMAIL_ADDRESS")
$SMTPServer = "MAIL_SERVER"
$SMTPPort = "25"
$SMTPSendingAddress = "EMAIL_ADDRESS"
 
#----These Alarms will be disabled and not send any email messages at all ----
$DisabledAlarms = $alarmfile | where-object priority -EQ "Disabled"
 
#----These Alarms will send a single email message and not repeat ----
$LowPriorityAlarms = $alarmfile | where-object priority -EQ "low"
 
#----These Alarms will repeat every 24 hours----
$MediumPriorityAlarms = $alarmfile | where-object priority -EQ "medium"
 
#----These Alarms will repeat every 4 hours----
$HighPriorityAlarms = $alarmfile | where-object priority -EQ "high"
 
foreach ($vcenterserver in $vcenterservers){
Connect-VIserver $vcenterserver -User $vcenterusername -Password $vcenteruserpwd
Get-AdvancedSetting -Entity $vcenterserver -Name mail.smtp.server | Set-AdvancedSetting -Value $SMTPServer -Confirm:$false
Get-AdvancedSetting -Entity $vcenterserver -Name mail.smtp.port | Set-AdvancedSetting -Value $SMTPPort -Confirm:$false
Get-AdvancedSetting -Entity $vcenterserver -Name mail.sender | Set-AdvancedSetting -Value $SMTPSendingAddress -Confirm:$false
 
#---Disable Alarm Action for Disabled Alarms---
Foreach ($DisabledAlarm in $DisabledAlarms) {
Get-AlarmDefinition -Name $DisabledAlarm.name | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
}
 
#---Set Alarm Action for Low Priority Alarms---
Foreach ($LowPriorityAlarm in $LowPriorityAlarms) {
Get-AlarmDefinition -Name $LowPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
Get-AlarmDefinition -Name $LowPriorityAlarm.name | New-AlarmAction -Email -To @($AlertEmailRecipients)
Get-AlarmDefinition -Name $LowPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
#Get-AlarmDefinition -Name $LowPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" # This ActionTrigger is enabled by default.
Get-AlarmDefinition -Name $LowPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
Get-AlarmDefinition -Name $LowPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}
 
#---Set Alarm Action for Medium Priority Alarms---
Foreach ($MediumPriorityAlarm in $MediumPriorityAlarms) {
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Set-AlarmDefinition -ActionRepeatMinutes (60 * 24) # 24 Hours
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | New-AlarmAction -Email -To @($AlertEmailRecipients)
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | Get-AlarmActionTrigger | Select -First 1 | Remove-AlarmActionTrigger -Confirm:$false
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" -Repeat
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
Get-AlarmDefinition -Name $MediumPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}
 
#---Set Alarm Action for High Priority Alarms---
Foreach ($HighPriorityAlarm in $HighPriorityAlarms) {
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail| Remove-AlarmAction -Confirm:$false
Get-AlarmDefinition -name $HighPriorityAlarm.name | Set-AlarmDefinition -ActionRepeatMinutes (60 * 4) # 4 hours
Get-AlarmDefinition -Name $HighPriorityAlarm.name | New-AlarmAction -Email -To @($AlertEmailRecipients)
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | Get-AlarmActionTrigger | Select -First 1 | Remove-AlarmActionTrigger -Confirm:$false
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" -Repeat
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Red" -EndStatus "Yellow"
Get-AlarmDefinition -Name $HighPriorityAlarm.name | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Green"
}
Disconnect-VIServer -Confirm:$False
}
