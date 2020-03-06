$out = @()
    $VMs = Get-Datacenter | Get-VMHost | Get-VM
    foreach ($VM in $VMs) {
        $VMx = Get-View $VM.ID
        $HW = $VMx.guest.net
        foreach ($dev in $HW)
        {
            foreach ($ip in $dev.ipaddress)
            {
                $out += $dev | select @{Name = "Name"; Expression = {$vm.name}}, @{Name = "IP"; Expression = {$ip}}, @{Name = "MAC"; Expression = {$dev.macaddress}}
            }
        }
    }
	
$out | Export-Csv -NoTypeInformation -Path "C:\Temp\VM-IP-Info.csv"
