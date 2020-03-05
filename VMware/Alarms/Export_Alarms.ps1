$stopWatch = [system.diagnostics.stopwatch]::startNew()
$stopWatch.Start()

#Define the log file
$Datestamp = Get-Date -Uformat %Y%m%d
$LogPath = "\\SERVER_NAME\ScriptLogs\6.5_Prep\Alarms\"
$FileName = $LogPath + $vCenter + "_Alarms" + ".csv"

# Start Logging
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

Write-Host "`nYou Picked: "$vCenter `n -ForegroundColor Blue

Start-sleep -s 3
 
# Connect to selected vCenter
Connect-VIServer $vCenter -WarningAction SilentlyContinue

$output = foreach ($alarm in (Get-AlarmDefinition | Sort Name | Get-AlarmAction))
{
    $threshold = foreach ($expression in ($alarm | %{$_.AlarmDefinition.ExtensionData.Info.Expression.Expression}))
    {
        if ($expression.EventTypeId -or ($expression | %{$_.Expression}))
        {
           if ($expression.Status) { switch ($expression.Status) { "red" {$status = "Alert"} "yellow" {$status = "Warning"} "green" {$status = "Normal"}}; "" + $status + ": " + $expression.EventTypeId } else { $expression.EventTypeId }         
        }
        elseif ($expression.EventType)
        {
            $expression.EventType
        }
        if ($expression.Yellow -and $expression.Red)
        {
            if (!$expression.Yellow) { $warning = "Warning: " + $expression.Operator } else { $warning = "Warning: " + $expression.Operator + " to " + $expression.Yellow };
            if (!$expression.Red) { $alert = "Alert: " + $expression.Operator } else { $alert = "Alert: " + $expression.Operator + " to " + $expression.Red };
            $warning + " " + $alert
        }
    }  
    $alarm | Select-Object @{N="Alarm";E={$alarm | %{$_.AlarmDefinition.Name}}},
                           @{N="Description";E={$alarm | %{$_.AlarmDefinition.Description}}},
                           @{N="Threshold";E={[string]::Join(" // ", ($threshold))}},
                           @{N="Action";E={if ($alarm.ActionType -match "SendEmail") { "" + $alarm.ActionType + " to " + $alarm.To } else { "" + $alarm.ActionType }}}
}

$output | Export-Csv $FileName -UseCulture -NoTypeInformation

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false