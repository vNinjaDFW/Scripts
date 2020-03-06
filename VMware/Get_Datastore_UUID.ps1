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
Write-Host "Choose the Cluster to scan:"
Write-Host ""
$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster:"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"."

ForEach ($dStore in (Get-Cluster $sCluster | Get-Datastore | Where-Object {$_.ExtensionData.Summary.MultipleHostAccess -eq 'true'} | Sort-Object Name))
{
$uuid = $dstore.ExtensionData.Info.Url
$dstore | select Name, $uuid
#$dstore.ExtensionData.Info.Url
}
