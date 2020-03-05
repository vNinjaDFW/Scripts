$vmhosts = Get-VMHost
$report = @()
foreach( $ESXHost in $vmhosts) {
$HWModel = get-vmHost $ESXHost | Select Name, Model
$esxcli = Get-ESXcli -vmhost $ESXHost

if($HWModel.Model -eq "ProLiant BL460c Gen8")
{

$info = $esxcli.network.nic.get("vmnic0").DriverInfo | select Driver,Hardwaremodel, FirmwareVersion, Version
$ModuleName = "$($info.Driver)"
$Firmware = "$($info.FirmwareVersion)"
$Driver = "$($info.Version)"
$lpfc = $esxcli.software.vib.list() | where { $_.name -eq "lpfc"}
$report += $info | select @{N="Hostname"; E={$ESXHost}},@{N="Hardware-Model"; E={$HWModel.Model}},@{N="Adapter-Firmware"; E={$Firmware}}, @{N="Network-Driver"; E={$Driver}}, @{N="FC-Driver"; E={$lpfc.version.substring(0,11)}}

}

elseif ($HWModel.Model -eq "ProLiant BL460c Gen9")

{

$info = $esxcli.network.nic.get("vmnic0").DriverInfo | select Driver, FirmwareVersion, Version
$ModuleName = "$($info.Driver)"
$Firmware = "$($info.FirmwareVersion)"
$Driver = "$($info.Version)"
$bnx2fc = $esxcli.software.vib.list() | where { $_.name -eq "scsi-bnx2fc"} 
$report += $info | select @{N="Hostname"; E={$ESXHost}},@{N="Hardware-Model"; E={$HWModel.Model}},@{N="Adapter-Firmware"; E={$Firmware.substring(2,8)}}, @{N="Network-Driver"; E={$Driver}}, @{N="FC-Driver"; E={$bnx2fc.version.substring(0,14)}}

}
}
$report | out-gridview