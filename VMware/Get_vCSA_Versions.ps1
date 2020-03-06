$vc = Get-Content .\vCenters.txt
Connect-VIServer -Server $vc
$global:DefaultVIServers | Select Name,Version,Build
Disconnect-VIServer $vc -Confirm:$false
