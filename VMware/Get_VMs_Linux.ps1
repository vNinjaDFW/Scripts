# Select a vCenter
Get-Content vCenterList.txt

[int]$ivCenter = Read-Host "`nSelect a vCenter Number:"

$vCenter = (Get-Content vCenterList.txt -TotalCount ($ivCenter+1))[-1]
$vCenter = $vCenter.substring(4)
$vCenter

If ($vCenter -eq 'End of List****') {
    Write-Host "Invalid Selection. Exiting."
    exit
}

Write-Host "`nYou Picked: "$vCenter `n 

Start-sleep -s 3
 
# Connect to selected vCenter
Connect-VIServer $vCenter -WarningAction SilentlyContinue

$sCluster = (Read-Host "Please enter the name of the Cluster:")

$VMs = Get-Cluster $sCluster | Get-VM
Foreach ($vm in $VMs){
     if ((Get-View $vm).Guest.GuestFullName -match "Linux"){
               Write-Host $vm.Name, " ---->" , (Get-View $vm).Guest.GuestFullName
     }
}
