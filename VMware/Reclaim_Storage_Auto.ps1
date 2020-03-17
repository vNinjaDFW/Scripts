# Adding PowerCLI core snapin
if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction silentlycontinue)) {
	add-pssnapin VMware.VimAutomation.Core
}

$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

$sCluster = 'XXX'

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER\ScriptLogs\Storage\Reclaims\"
$FileName = $LogPath + $sCluster + "_" + $Datestamp + ".txt"

# Start Logging
$Timestart = Get-Date
Start-Transcript $FileName

Connect-VIServer XXX -ErrorAction SilentlyContinue | Out-Null
$sHosts = Get-Cluster $sCluster | Get-VMHost
$SSH = 'True'

ForEach ($sHost in $sHosts){
$gSSH = (Get-VMHostService -VMHost $sHost | Where-Object {$_.Key -eq 'TSM-SSH'}).Policy -eq 'on'
if ($gSSH -like $SSH){
$gHost = $sHost
}}

Write-Host 'Using Host' $gHost
$User = 'root'
$Password = 'XXX'

ForEach ($dStore in (Get-Datastore -VMHost $gHost | Where-Object {$_.ExtensionData.Summary.MultipleHostAccess -eq 'true'} | Sort-Object Name))
{
    Write-Host " -- Starting Unmap on DataStore $dStore -- " -ForegroundColor 'yellow' 
    cmd /c plink.exe -ssh $gHost -l $User -pw $Password -batch "esxcli storage vmfs unmap -l $dStore"
    Write-Host " -- Unmap has completed on DataStore $dStore -- " -ForegroundColor 'green'
}

$stopWatch.Stop()
Write-Host "Total Runtime:" $stopWatch.Elapsed.Hours "Hours" $stopWatch.Elapsed.Minutes "minutes and" $stopWatch.Elapsed.Seconds "seconds." -BackgroundColor White -ForegroundColor Black

Stop-Transcript

# Send EMail
$vCenterSettings = Get-View -Id 'OptionManager-VpxSettings'
$MailSender = ($vCenterSettings.Setting | Where-Object { $_.Key -eq "mail.sender"}).Value
$MailSmtpServer = ($vCenterSettings.Setting | Where-Object { $_.Key -eq "mail.smtp.server"}).Value
Send-MailMessage -from $MailSender -to "XXX" -subject $sCluster -body 'Storage Reclaims Completed' -smtpServer $MailSmtpServer
