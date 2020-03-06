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

# Select the Cluster
Write-Host ""
Write-Host "Choose the Cluster to report on:" -BackgroundColor Yellow -ForegroundColor Black
Write-Host ""
$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster:"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"." -ForegroundColor Blue

$report = Get-Cluster $sCluster | Get-VM | Select Name, @{N="Datastore";E={[string]::Join(',',(Get-Datastore -Id $_.DatastoreIdList | Select -ExpandProperty Name))}}, @{N="Folder";E={$_.Folder.Name}}
$report | Export-CSV C:\Temp\$sCluster_VMswithDS.csv

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false
