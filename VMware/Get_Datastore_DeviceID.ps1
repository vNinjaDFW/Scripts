$sCluster = (Read-Host "Enter the name of the Cluster where Storage is being removed from:")

Get-Cluster $sCluster | Get-VMHost | Get-Datastore |
Where-Object {$_.ExtensionData.Info.GetType().Name -eq "VmfsDatastoreInfo"} |
ForEach-Object {
if ($_)
{
$Datastore = $_
$Datastore.ExtensionData.Info.Vmfs.Extent |
Select-Object -Property @{Name="Name";Expression={$Datastore.Name}},
DiskName
}
}