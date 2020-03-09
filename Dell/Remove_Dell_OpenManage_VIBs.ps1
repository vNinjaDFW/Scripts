$ClusterName = Read-Host "Please enter the name of the Cluster (Dells):"
Get-Cluster $ClusterName | Get-VMHost | foreach {
 Write-Host ("Removing Dell OpenManage VIB For Host " + $_.name)
 $x = ""
 $x = Get-ESXCli -vmhost $_
 $x.software.vib.remove($false, $false, $true, $false, @("OpenManage"))
}
