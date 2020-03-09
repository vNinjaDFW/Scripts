Function Get-VMHostHba
{
	
<#
.SYNOPSIS
	Get VMHost Fibre Channel HBA.
.DESCRIPTION
	This function gets VMHost Fibre Channel Host Bus Adapter info.
.PARAMETER VMHost
	Specifies ESXi host object(s), returned by Get-VMHost cmdlet.
.PARAMETER Nolink
	If specified, only disconnected adapters returned.
.PARAMETER FormatWWN
	Specifies how to format WWN property.
.EXAMPLE
	PS C:\> Get-VMHost |sort Name |Get-VMHostHba -Verbose |? {$_.SpeedGbps} |epcsv -notype .\HBA.csv
	Export connected HBAs only.
.EXAMPLE
	PS C:\> Get-Cluster PROD |Get-VMHost -State Connected |Get-VMHostHba |? {$_.SpeedGbps -gt 4} |ft -au
	Get all connected VMHost HBAs with link speed greater than 4Gbps.
.EXAMPLE
	PS C:\> Get-VMHost 'esxdmz[1-9].*' |sort Name |Get-VMHostHba -Nolink |Format-Table -AutoSize
	Get disconnected HBAs only.
.EXAMPLE
	PS C:\> Get-Cluster PROD |Get-VMHost |Get-VMHostHba |? {$_.SpeedGbps -eq 8} |group VMHost |sort Name |select Name, Count, @{N='vmhba';E={($_ |select -expand Group).HBA}}
	Get all 8Gb VMHost HBAs in a cluster, group by VMHost.
.EXAMPLE
	PS C:\> Get-VMHost |sort Parent, Name |Get-VMHostHba |? {$_.SpeedGbps} |group VMHost |select Name, Count, @{N='vmhba';E={(($_ |select -expand Group).HBA) -join ', '}}
	Get all connected VMHost HBAs in an Inventory, group by VMHost and sort by Cluster.
.EXAMPLE
	PS C:\> Get-VMHost 'esxprd1.*' |Get-VMHostHba
.NOTES
	Author      :: Roman Gelman @rgelman75
	Shell       :: Tested on PowerShell 5.0|PowerCLi 6.5.1
	Platform    :: Tested on vSphere 5.5/6.5|VCenter 5.5U2/VCSA 6.5
	Requirement :: PowerShell 3.0
	Version 1.0 :: 15-Jun-2017 :: [Release] :: Publicly available
	Version 1.1 :: 13-Nov-2017 :: [Improvement] :: Added property vSphere
.LINK
	https://ps1code.com/2017/06/18/esxi-peripheral-devices-powercli
#>
	
	[CmdletBinding()]
	[Alias("Get-ViMVMHostHba", "esxhba")]
	[OutputType([PSCustomObject])]
	Param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VMHost]$VMHost
		 ,
		[Parameter(Mandatory = $false)]
		[Alias("Down")]
		[switch]$Nolink
		 ,
		[Parameter(Mandatory = $false, Position = 0)]
		[ValidateSet('XX:XX:XX:XX:XX:XX:XX:XX', 'xx:xx:xx:xx:xx:xx:xx:xx',
					 'XXXXXXXXXXXXXXXX', 'xxxxxxxxxxxxxxxx')]
		[string]$FormatWWN = 'XX:XX:XX:XX:XX:XX:XX:XX'
	)
	
	Begin
	{
		$ErrorActionPreference = 'Stop'
		$WarningPreference = 'SilentlyContinue'
		$StatVMHost = 0
		$StatHba = 0
		$StatDown = 0
		
		switch -casesensitive -regex ($FormatWWN)
		{
			'^xxx' { $WwnCase = 'x'; $WwnColon = $false; Break }
			'^xx:' { $WwnCase = 'x'; $WwnColon = $true; Break }
			'^XXX' { $WwnCase = 'X'; $WwnColon = $false; Break }
			'^XX:' { $WwnCase = 'X'; $WwnColon = $true }
		}
		
		$FunctionName = '{0}' -f $MyInvocation.MyCommand
		Write-Verbose "$FunctionName started at [$(Get-Date)]"
	}
	Process
	{
		Try
		{
			$StatVMHost += 1
			$HBAs = ($VMHost | Get-View -Verbose:$false).Config.StorageDevice.HostBusAdapter
			$esxcli = Get-EsxCli -VMHost $VMHost.Name -V2 -Verbose:$false
			$vSphere = $esxcli.system.version.get.Invoke()
			
			foreach ($Hba in $HBAs)
			{
				Write-Progress -Activity $FunctionName -Status "VMHost [$($VMHost.Name)]" -CurrentOperation "HBA [$($Hba.Device)]"
				
				if ($Hba.PortWorldWideName)
				{
					$StatHba += 1
					### WWN ###
					$WWN = "{0:$WwnCase}" -f $Hba.PortWorldWideName
					if ($WwnColon) { $WWN = $WWN -split '(.{2})' -join ':' -replace ('(^:|:$)', '') -replace (':{2}', ':') }
					### Vendor ###
					$Vendor = switch -regex ($Hba.Driver)
					{
						'^lp' { 'Emulex'; Break }
						'^ql' { 'QLogic'; Break }
						'^b(f|n)a' { 'Brocade'; Break }
						'^aic' { 'Adaptec'; Break }
						Default { 'Unknown' }
					}
					
					$res = [pscustomobject] @{
						VMHost = $VMHost.Name
						vSphere = "$([regex]::Match($vSphere.Version, '^\d\.\d').Value)U$($vSphere.Update)$([regex]::Match($vSphere.Build, '-\d+').Value)"
						HBA = $Hba.Device
						WWN = $WWN
						SpeedGbps = $Hba.Speed
						Vendor = $Vendor
						Model = [regex]::Match($Hba.Model, '^.+\d+Gb').Value
						Driver = $Hba.Driver
					}
					if (!$res.SpeedGbps) { $StatDown += 1 }
					
					if ($Nolink) { if (!($res.SpeedGbps)) { $res } }
					else { $res }
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
		Write-Verbose "$FunctionName Statistic: Total VMHost: [$StatVMHost], Total HBA: [$StatHba], Down: [$StatDown]"
	}
	
} #EndFunction Get-VMHostHba
