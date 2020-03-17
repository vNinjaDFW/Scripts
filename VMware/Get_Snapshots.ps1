<#
SYNOPSIS
	Snapshot Notification
Description
	This script collects all of the outstanding snapshots in the vcenter
	and emails the results to $toAddr.
.NOTES
    File Name		: Get_Snapshots.ps1
    Author			: Ryan Patel
    Prerequisite	: vCenter, EMail Addresses, SMTP
    Creation Date	: 10/6/2017
	Version			: 1.0
	Update Log:
#>

# Define Variables
Write-Host "Defining variables"
$fromAddr = "XXX" # Enter the FROM address for the e-mail alert
$toAddr = @("XXX") # Enter the TO address for the e-mail alert
$smtpsrv = "XXX" # Enter the FQDN or IP of a SMTP relay
$smtpsrvbackup = "XXX"
$attachmentPref = 0 # Enter 1 if you would also like an attachment of the report in CSV format
$fullalert=1 # Set to 1 to enable email notifications on no snapshots

# END USER DEFINED VARS
$ErrorActionPreference = "SilentlyContinue"
$error.clear()
$date = Get-Date
$hostname=$env:computername

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

## Collect the VMs and check for available snapshots.
#$VMsWithSnaps = @(Get-Cluster "XXX" | Get-VM | Get-Snapshot | Select vm,name,sizemb,created)
Write-Host "Querying for Snap-Shots"
$VMsWithSnaps = @(Get-Datacenter | Get-VM | Get-Snapshot | Select vm,name,sizemb,created)

## Determine if snapshots were detected and then send appropriate email.
if($VMsWithSnaps -ne $null){
    $body = @("
        <center><table border=1 width=90% cellspacing=0 cellpadding=8 bgcolor=Black cols=4>
        <tr bgcolor=White align=center valign=middle><b><td><b>Virtual Machine</b></td><td><b>Snapshot</b></td><td><b>Size in MB</b></td><td><b>Time of Creation</b></td></tr>")
        $i = 0
        do {
            if($i % 2){
                $body += "<tr bgcolor=#99CCFF><td>$($VMsWithSnaps[$i].VM)</td><td>$($VMsWithSnaps[$i].Name)</td><td>$($VMsWithSnaps[$i].Sizemb)</td><td>$($VMsWithSnaps[$i].Created)</td></tr>";$i++
            }
            else {
                $body += "<tr bgcolor=#D6EBFF><td>$($VMsWithSnaps[$i].VM)</td><td>$($VMsWithSnaps[$i].Name)</td><td>$($VMsWithSnaps[$i].Sizemb)</td><td>$($VMsWithSnaps[$i].Created)</td></tr>";$i++
            }
        }
        while ($VMsWithSnaps[$i] -ne $null)

    $body += "</font></table></center><p>Executed from $hostname"

    Write-Host "Sending Email"
    ##Send email alerting recipients about snapshots.
    #$ErrorActionPreference = "stop"
    if($attachmentPref){
        foreach ($strAddr in $toAddr){
            $VMsWithSnaps | Export-CSV "SnapshotReport $($date.month)-$($date.day)-$($date.year).csv"
            Send-MailMessage -To "$strAddr" -From "$fromAddr" -Subject "WARNING: VMware Snapshot Daily Report - $date" -Body "$body" -Attachments "SnapshotReport $($date.month)-$($date.day)-$($date.year).csv" -SmtpServer "$smtpsrv" -BodyAsHtml
            Remove-Item "SnapshotReport $($date.month)-$($date.day)-$($date.year).csv"
            if ($error[0] -ne $null) {
                Send-MailMessage -To "$strAddr" -From "$fromAddr" -Subject "WARNING: VMware Snapshot Daily Report - $date" -Body "$body`r`n`r`nMailed from $smtpsrvbackup" -Attachments "SnapshotReport $($date.month)-$($date.day)-$($date.year).csv" -SmtpServer "$smtpsrvbackup" -BodyAsHtml
                Remove-Item "SnapshotReport $($date.month)-$($date.day)-$($date.year).csv"
            }
        }
    }
    else {
        foreach ($strAddr in $toAddr){
            Send-MailMessage -To "$strAddr" -From "$fromAddr" -Subject "WARNING: VMware Snapshot Daily Report - $date" -Body "$body" -SmtpServer "$smtpsrv" -BodyAsHtml
            if ($error[0] -ne $null) {
                Send-MailMessage -To "$strAddr" -From "$fromAddr" -Subject "WARNING: VMware Snapshot Daily Report - $date" -Body "$body <p>nMailed from $smtpsrvbackup" -SmtpServer "$smtpsrvbackup" -BodyAsHtml
            }
        }
    }
}
else {
    foreach ($strAddr in $toAddr){
        Write-Host "No Snapshots detected"
        if ($fullalert){
            Send-MailMessage -To $strAddr -From "$fromAddr" -Subject "VMware Snapshot Daily Report - $date" -Body "The snapshot manager script found no snapshots.<p>Executed from $hostname" -SmtpServer "$smtpsrv" -BodyAsHtml
            if ($error[0] -ne $null) {
                Send-MailMessage -To $strAddr -From "$fromAddr" -Subject "VMware Snapshot Daily Report - $date" -Body "The snapshot manager script found no snapshots.<p>Executed from $hostname<p>Mailed from $smtpsrvbackup" -SmtpServer "$smtpsrvbackup" -BodyAsHtml
            }
        }
    }
}

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false

Stop-Transcript
