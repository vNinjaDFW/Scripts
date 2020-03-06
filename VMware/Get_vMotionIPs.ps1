$array = @()
$Clusters = Get-Cluster | Sort Name
ForEach ($Cluster in $Clusters){
$VmHosts = $Cluster | Get-VmHost | Where {$_.ConnectionState -eq "Connected"} | Sort Name
ForEach ($VmHost in $VmHosts){
$Array += Get-VMHostNetworkAdapter -VMHost $VmHost.Name -VMKernel | Where {$_.VMotionEnabled -eq "True"} | select VmHost,IP
}
}
$array | Out-GridView
