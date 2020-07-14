$info = @()
foreach($dvPortgroup in (Get-VirtualPortgroup -Distributed | Sort Name)){
$dvPortgroupInfo = New-Object PSObject -Property @{
Name = $dvPortgroup.Name
VlanId = $dvPortgroup.ExtensionData.Config.DefaultPortConfig.Vlan.VlanId
VMs = $dvPortgroup.ExtensionData.vm.count
}
$info += $dvPortgroupInfo
}
$info | Export-Csv -UseCulture -NoTypeInformation vlans.csv
