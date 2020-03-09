Function Get-VMHostPnic
{
	
<#
.SYNOPSIS
	Get VMHost PNIC(s).
.DESCRIPTION
	This function gets VMHost physical NIC (Network Interface Card) info.
.PARAMETER VMHost
	Specifies ESXi host object(s), returned by Get-VMHost cmdlet.
.PARAMETER SpeedMbps
	If specified, only vmnics that match this link speed are returned.
.PARAMETER Vendor
	If specified, only vmnics from this vendor are returned.
.EXAMPLE
	PS C:\> Get-VMHost |sort Name |Get-VMHostPnic -Verbose |? {$_.SpeedMbps} |epcsv -notype .\NIC.csv
	Export connected NICs only.
.EXAMPLE
	PS C:\> Get-Cluster PROD |Get-VMHost -State Connected |Get-VMHostPnic |? {1..999 -contains $_.SpeedMbps} |ft -au
	Get all connected VMHost NICs with link speed lower than 1Gb.
.EXAMPLE
	PS C:\> Get-VMHost 'esxdmz[1-9].*' |sort Name |Get-VMHostPnic -Vendor Emulex, HPE |Format-Table -AutoSize
	Get vendor specific NICs only.
.EXAMPLE
	PS C:\> Get-Cluster PROD |Get-VMHost |Get-VMHostPnic -SpeedMbps 10000} |group VMHost |sort Name |select Name, Count, @{N='vmnic';E={($_ |select -expand Group).PNIC}}
	Get all 10Gb VMHost NICs in a cluster, group by VMHost.
.EXAMPLE
	PS C:\> Get-VMHost |sort Parent, Name |Get-VMHostPnic -SpeedMbps 0 |group VMHost |select Name, Count, @{N='vmnic';E={(($_ |select -expand Group).PNIC) -join ', '}}
	Get all connected VMHost NICs in an Inventory, group by VMHost and sort by Cluster.
.EXAMPLE
	PS C:\> Get-VMHost 'esxprd1.*' |Get-VMHostPnic -Verbose
.NOTES
	Author      :: Roman Gelman @rgelman75
	Shell       :: Tested on PowerShell 5.0 | PowerCLi 6.5.2
	Platform    :: Tested on vSphere 5.5/6.5 | VCenter 5.5U2/VCSA 6.5U1
	Requirement :: PowerShell 3.0
	Version 1.0 :: 15-Jun-2017 :: [Release] :: Publicly available
	Version 1.1 :: 12-Nov-2017 :: [Improvement] :: Added properties: vSphere, DriverVersion, Firmware
	Version 1.2 :: 13-Nov-2017 :: [Change] :: The -Nolink parameter replaced with two new parameters -SpeedMbps and -Vendor
.LINK
	https://ps1code.com/2017/06/18/esxi-peripheral-devices-powercli
#>
	
	[CmdletBinding()]
	[Alias("Get-ViMVMHostPnic", "esxnic")]
	[OutputType([PSCustomObject])]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost]$VMHost
		 ,
		[Parameter(Mandatory = $false)]
		[uint32]$SpeedMbps
		 ,
		[Parameter(Mandatory = $false)]
		[ValidateSet('Emulex', 'Intel', 'Broadcom', 'HPE', 'Unknown', IgnoreCase = $true)]
		[string[]]$Vendor
	)
	
	Begin
	{
		$ErrorActionPreference = 'Stop'
		$WarningPreference = 'SilentlyContinue'
		$StatVMHost = 0
		$Statvmnic = 0
		$StatBMC = 0
		$StatDown = 0
		$FunctionName = '{0}' -f $MyInvocation.MyCommand
		Write-Verbose "$FunctionName started at [$(Get-Date)]"
	}
	Process
	{
		Try
		{
			$StatVMHost += 1
			$PNICs = ($VMHost | Get-View -Verbose:$false).Config.Network.Pnic
			$esxcli = Get-EsxCli -VMHost $VMHost.Name -V2 -Verbose:$false
			$vSphere = $esxcli.system.version.get.Invoke()
			
			foreach ($Pnic in $PNICs)
			{
				Write-Progress -Activity $FunctionName -Status "VMHost [$($VMHost.Name)]" -CurrentOperation "PNIC [$($Pnic.Device)]"
				
				if ($Pnic.Device -match 'vmnic')
				{
					$Statvmnic += 1
					$NicVendor = switch -regex ($Pnic.Driver)
					{
						'^(elx|be)' { 'Emulex'; Break }
						'^(igb|ixgb|e10)' { 'Intel'; Break }
						'^(bnx|tg|ntg)' { 'Broadcom'; Break }
						'^nmlx' { 'HPE' }
						Default { 'Unknown' }
					}
					
					$NicInfo = $esxcli.network.nic.get.Invoke(@{ nicname = "$($Pnic.Device)" })
					
					$res = [pscustomobject] @{
						VMHost = $VMHost.Name
						vSphere = "$([regex]::Match($vSphere.Version, '^\d\.\d').Value)U$($vSphere.Update)$([regex]::Match($vSphere.Build, '-\d+').Value)"
						PNIC = $Pnic.Device
						MAC = ($Pnic.Mac).ToUpper()
						SpeedMbps = if ($Pnic.LinkSpeed.SpeedMb) { $Pnic.LinkSpeed.SpeedMb } else { 0 }
						Vendor = $NicVendor
						Driver = $Pnic.Driver
						DriverVersion = $NicInfo.DriverInfo.Version
						Firmware = $NicInfo.DriverInfo.FirmwareVersion
					}
					
					if (!$res.SpeedMbps) { $StatDown += 1 }
					
					### Return output ###
					$Next = if ($PSBoundParameters.ContainsKey('SpeedMbps')) { if ($res.SpeedMbps -eq $SpeedMbps) { $true }
						else { $false } }
					else { $true }
					if ($Next) { if ($PSBoundParameters.ContainsKey('Vendor')) { if ($Vendor -icontains $res.Vendor) { $res } }
						else { $res } }
				}
				else
				{
					$StatBMC += 1
				}
			}
		}
		Catch
		{
			"{0}" -f $Error.Exception.Message
		}
	}
	End
	{
		Write-Progress -Activity "Completed" -Completed
		Write-Verbose "$FunctionName finished at [$(Get-Date)]"
		Write-Verbose "$FunctionName Statistic: Total VMHost: [$StatVMHost], Total vmnic: [$Statvmnic], Down: [$StatDown], BMC: [$StatBMC]"
	}
	
} #EndFunction Get-VMHostPnic
