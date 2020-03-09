# Send EMail
$vCenterSettings = Get-View -Id 'OptionManager-VpxSettings'
$MailSender = ($vCenterSettings.Setting | Where-Object { $_.Key -eq "mail.sender"}).Value
$MailSmtpServer = ($vCenterSettings.Setting | Where-Object { $_.Key -eq "mail.smtp.server"}).Value
Send-MailMessage -from $MailSender -to XXX@domain.com -subject 'SMTP Test' -body 'Testing SMTP Functionality' -smtpServer $MailSmtpServer -UseSSL
