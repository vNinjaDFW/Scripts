# *******************************************************************
# * Title:            Copy vDS PGs to vSS
# * Purpose:          This script copies vDS PGs to vSS
# * Args:             vCenter & Cluster Name
# * Usage:			  Create-VSS.ps1 -h [Target ESXi Host] -s [dVS Name] -d [vSS Name]
# * Author:           Ryan Patel
# * Creation Date:    03/09/2018
# * Last Modified:    03/09/2018
# * Version:          1.0
# *******************************************************************
param
(
	[alias("h")]
	[string]$thisHost = $(Read-Host -Prompt "Enter the Target ESXi Host"),
	[alias("s")]
	[string]$source = $(Read-Host -Prompt "Enter the Source vDS Name"),
	[alias("d")]
	[string]$destination = $(Read-Host -Prompt "Enter the Destination vSS Name")
)
#Create an empty array to store the port group translations
$pgTranslations = @()

#Get the destination vSwitch
if (!($destSwitch = Get-VirtualSwitch -host $thisHost -name $destination)){write-error "$destination vSwitch not found on $thisHost";exit 10}
#Get a list of all port groups on the source distributed vSwitch
if (!($allPGs = Get-vdswitch -name $source | Get-vdportgroup)){write-error "No port groups found for $source Distributed vSwitch";exit 11}
foreach ($thisPG in $allPGs)
{
	$thisObj = new-object -Type PSObject
	$thisObj | add-member -MemberType NoteProperty -Name "dVSPG" -Value $thisPG.Name
	$thisObj | add-member -MemberType NoteProperty -Name "VSSPG" -Value "$($thisPG.Name)-VSS"
	new-virtualportgroup -virtualswitch $destSwitch -name "$($thisPG.Name)-VSS"
	# Ensure that we don't try to tag an untagged VLAN
	if ($thisPG.vlanconfiguration.vlanid)
	{
		Get-virtualportgroup -virtualswitch $destSwitch -name "$($thisPG.Name)-VSS" | Set-VirtualPortGroup -vlanid $thisPG.vlanconfiguration.vlanid
	}
	$pgTranslations += $thisObj
} 

$pgTranslations
