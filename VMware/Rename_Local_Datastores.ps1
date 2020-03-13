<#
SYNOPSIS
	Rename ESXi Local Datastores
Description
	This script will get the local datastores of a Cluster and rename them
	to $prefix_HOSTNAME and move these Datastores to the Local_Datastores Folder.
.NOTES
    File Name		: Rename_Local_Datastores.ps1
	  Usage			: Rename_Local_Datastores.ps1 -cluster XXX -prefix XXX
    Author			: Ryan Patel
    Prerequisite	: Parameters
    Creation Date	: 07/11/2019
	Version			: 1.0
#>
$totalTime = [system.diagnostics.stopwatch]::StartNew()

[cmdletbinding(SupportsShouldProcess=$True)]
param(
  $cluster = "CLUSTER_NAME",
  $prefix = "local_storage_"
)

Get-Cluster $cluster | Get-VMHost | % { $_ | Get-Datastore | ? {$_.name -match "^*datastore( \(\d+\))?$"} | Set-Datastore -Name "$prefix$($_.name.split(".")[0])"}
Get-Datastore $prefix* | Move-Datastore -Destination Local_Datastores
}

$totalTime.Stop()
