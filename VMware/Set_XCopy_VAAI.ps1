[string]$sCluster = (Read-Host "Please enter the name of the Cluster:")
$scope = Get-Cluster $sCluster | Get-VMHost *
ForEach ($esx in $scope){
$esxcli = Get-EsxCli -VMHost $esx
$esxcli.storage.core.claimrule.remove("VAAI", $null, "65430")
$esxcli.storage.core.claimrule.add($null, $null, $null, "VAAI", $null, $null, $null, $null, $null, $null,"SYMMETRIX",  "VMW_VAAIP_SYMM", "65430", $null, $null, "vendor", "EMC", $null, $null, "240", $true , $true)
$esxcli.storage.core.claimrule.load("VAAI")
$esxcli.storage.core.claimrule.list("VAAI")
}
