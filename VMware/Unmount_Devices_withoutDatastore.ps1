# Declare the variables
$hostslist = Import-CSV FILENAME.csv #Single column with Hostname, Host in first cell
$luns = Import-CSV FILENAME.csv #Single column with naaIDs, naa in first cell

Function Detach-Disk{
    param(
    [VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost]$VMHost,
    [string]$CanonicalName
    )
   
    $storSys = Get-View $VMHost.Extensiondata.ConfigManager.StorageSystem
    $lunUuid = (Get-ScsiLun -VmHost $VMHost | where {$_.CanonicalName -eq $CanonicalName}).ExtensionData.Uuid
   
    $storSys.DetachScsiLun($lunUuid)
}
 
Function Get-DiskState
{
    param(
    [VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost]$VMHost,
    [string]$CanonicalName
    )
 
    $storSys = Get-View $VMHost.Extensiondata.ConfigManager.StorageSystem
    $lun = Get-ScsiLun -CanonicalName $CanonicalName -VmHost $VMHost -ErrorAction SilentlyContinue
 
    if(!$lun){'detached'}
    else{'attached'}
}

$report = @()

foreach ($vmhost in $hostslist){
    $hostname=$vmhost.host
    write-host "Starting $hostname"
    $esx = get-vmhost $hostname
    foreach ($lun in $luns){
        $naa=$lun.naa
        $lunState = Get-DiskState -VMHost $esx -CanonicalName $naa
        write-host "Detaching LUN $naa from $esx"
        if($lunState -eq 'attached'){
            Detach-Disk -vmhost $esx -CanonicalName $naa
        }
        $report += New-Object PSObject -Property @{
            VMHost = $esx.Name
            LUN = $naa
            PreState = $lunState
        }
    }
}

$report | Export-Csv lunreport.csv -NoTypeInformation -UseCulture
