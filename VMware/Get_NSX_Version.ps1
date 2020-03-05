$WarningPreference="SilentlyContinue"
$global:isExit = $false
$numHosts=0
$global:scriptDir = Split-Path $MyInvocation.MyCommand.Path
$global:userOptions = @{}
$logPathDir = "\\SERVER\ScriptLogs\Misc\"
$logfile = "$logPathDir\Get_NSX_Version_$(get-date -format `"yyyymmdd_hhmmss`").txt"

Function logger($strMessage, $logOnly)
{
	$curDateTime = get-date -format "hh:mm:ss"
	$entry = "$curDateTime :> $strMessage"
	if (!$logOnly) {
		write-host $entry
		$entry | out-file -Filepath $logfile -append
	} else {
		$entry | out-file -Filepath $logfile -append
	}
}

$totalTime = [system.diagnostics.stopwatch]::StartNew()

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

try{
	Write-host "Connecting to $vCenter, please wait.." -ForegroundColor green
	#Connect to vCenter
	Connect-VIServer $vCenter -ErrorAction Stop | Out-Null
	logger "Connected to $vCenter"  -logOnly:$true
   }
   catch [Exception]{
	$status = 1
	$exception = $_.Exception
	Write-Host "Could not connect to $vCenter" -ForegroundColor Red
	$msg = "Could not connect to $vCenter"
	logger "$msg $status $error[0]"
}

logger "Getting NSX-V version..."
$extensionManager = Get-View ExtensionManager
foreach ($extension in $extensionManager.ExtensionList) {
    if($extension.key -eq "com.vmware.vShieldManager") {
        Write-Host "NSX-V is installed with version"$extension.Version
		$nsxVersion = $extension.Version
		logger "NSX-V is installed with version $nsxVersion"
    } elseif($extension.key -eq "com.vmware.nsx.management.nsxt") {
        Write-Host "NSX-T is installed with version"$extension.Version
		$nsxVersion = $extension.Version
		logger "NSX-T is installed with version $nsxVersion"
    }
}

# Disconnect from vCenter
Write-Host "Disconnecting from $vCenter.." -ForegroundColor green
Disconnect-VIServer $vCenter -confirm:$false
logger "Disconnected from $vCenter"  -logOnly:$true

$totalTime.Stop()
logger "Total RunTime: $($totalTime.Elapsed)"