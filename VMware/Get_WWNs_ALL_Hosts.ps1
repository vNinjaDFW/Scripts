$path = "\\SERVER\_Inventory\WWNs\"
$vCenters = "vcsa01","vcsa02","vcsa69"

foreach ($vCenter in $vCenters) {
    Connect-VIServer "$vCenter" -ErrorAction SilentlyContinue
	$report = Get-Datacenter | %{
	ForEach ($sCluster in (Get-Cluster)){
	Get-Cluster $sCluster | Get-VMHost | Get-VMHostHBA | Select @{N="Cluster";E={$sCluster}},VMHost,HBA, WWN, SpeedGbps
	}}
	$report | Export-CSV $path\$vCenter.csv -NoTypeInformation
	Disconnect-VIServer -Server * -Force:$true -Confirm:$false
}
