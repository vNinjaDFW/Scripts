$vCenters = gc .\vCenters.txt
$report = @()
foreach ($vCenter in $vCenters) {
	Connect-viserver "$vCenter"
    $report = @()
	$vmhosts = Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"}
foreach($vmhost in $vmhosts){
  $hss = Get-View $vmhost.Extensiondata.ConfigManager.StorageSystem
  $lunTab = @{}
  $hss.StorageDeviceInfo.ScsiLun | %{$lunTab.Add($_.Key,$_.CanonicalName)
  }
  $pathTab = @{}
  $hss.StorageDeviceInfo.MultipathInfo.Lun | %{$pathState = @($_.Path | Group-Object -Property PathState | where {$_.Name -eq "active"} | Select -ExpandProperty Group)
    if($pathTab.ContainsKey($_.Lun)){
      $pathTab[$_.Lun] += $pathState.Count
    }
    else{
      $pathTab.Add($lunTab[$_.Lun],$pathState.Count)
    }
  }
  foreach($mount in ($hss.FileSystemVolumeInfo.MountInfo | where {$_.Volume.Type -eq "VMFS"})){
	$report += $mount.Volume.Extent | Select @{N="VMHost";E={$VMHost.Name}}, @{N="Datastore";E={$mount.Volume.Name}}, @{N="LUN";E={$_.DiskName}}, @{N="ActivePaths";E={$pathTab[$_.DiskName]}}
}
}
	$report | Export-CSV C:\Temp\ActivePaths_$vCenter.csv -NoType
	Disconnect-VIServer -Server * -Force:$true -Confirm:$false
}