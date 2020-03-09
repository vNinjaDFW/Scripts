# How To Use This Function
# Write-Host "Usage: MigrateDVSwitch-Adapter -VMHost XXX -Interface vmk1 -NetworkName Vmotion -VirtualSwtich vSwitch0 -Vlan 7777"
function MigrateDVSwitch-Adapter{
    param ([string]$VMHost,[string]$Interface,[string]$NetworkName,[int]$Vlan,[string]$VirtualSwitch)
    $VMHostobj = Get-VMHost $VMHost

	#Get Network ID
    $networkid = $VMHostObj.ExtenSionData.Configmanager.NetworkSystem


	# ------- AddPortGroup to Standard Switch
	$portgrp = New-Object VMware.Vim.HostPortGroupSpec
	$portgrp.name = $NetworkName
	$portgrp.vlanId = $Vlan
	$portgrp.vswitchName = $VirtualSwitch
	$portgrp.policy = New-Object VMware.Vim.HostNetworkPolicy
	$_this = Get-View -Id $networkid
	$_this.AddPortGroup($portgrp)

    # ------- UpdateVirtualNic ----Migrates the virtual interface to the standard switch
	$nic = New-Object VMware.Vim.HostVirtualNicSpec
	$nic.portgroup =$NetworkName
	$_this = Get-View -Id $networkid
	$_this.UpdateVirtualNic($Interface, $nic)

    }
