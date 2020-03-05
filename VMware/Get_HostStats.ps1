#############################################################################
## PowerCLI Script for collecting the ESXi Host Info for the ITDashboard.
## Exported to CSVs per vCenter.
##############################################################################

Set-Location D:\_Scripts\ITDashboard

function usage {
  echo ""
  write-host "Get_HostStats.ps1 [-help] | [-out OutFile.CSV] " -foregroundcolor "white"
  echo ""
  write-host "-help prints this information" -foregroundcolor "yellow"
  echo ""
  write-host "-v specify a vCenter (optional)" -foregroundcolor "yellow"
  echo ""
  exit
}

if ("-help", "--help", "-?", "--?", "/?" -contains $args[0]) {
  usage
}

$vCSrvLst = @()

######## Main Section ########  
foreach ($VCSvr in $vCSrvLst) {

    connect-viserver "$VCSvr" -ErrorAction SilentlyContinue | Out-Null

    $QuickHostInv = @() 
    write-host "Exporting Host Details for vCenter: $VCSvr to: ESXHostDetails_$VCSvr.csv"


    $HostList = @()
    $HostList = Get-VMHost | Sort -Unique

    #Begin grabbing and formatting data
    ForEach ($VMHost in $HostList) {
        $HRow = "" | select vCenter, ClusterName, HostName, State, HostModel, ServiceTag, UUID, TotalProcs, CpuSockets, CpuCoresPer, CpuTotalMhz, TotalMemory_GB, Mem_Usage_GB, NumofVMs
        
        $HRow.vCenter = "$VCSvr"

        #Standalone hosts marked as orphaned
        If($VMHost.Parent.Type -eq "HostAndCluster") {
            $HRow.ClusterName = "Orphaned"
        }
        Else {
	    $HRow.ClusterName = $VMHost.Parent.Name
        }
		
		$HRow.HostName = "$VMHost"
		$HRow.State = $VMHost.ConnectionState
		$HRow.HostModel = $VMHost.Model
		$HRow.ServiceTag = ($VMHost.ExtensionData.Hardware.SystemInfo.OtherIdentifyingInfo | Where-Object {$_.IdentifierType.Key -eq "ServiceTag"}).IdentifierValue
		$HRow.UUID = $VMHost.ExtensionData.Hardware.SystemInfo.Uuid
		$HRow.TotalProcs = $VMHost.NumCpu
		$HRow.CpuSockets = $VMHost.ExtensionData.Hardware.CpuInfo.NumCpuPackages
		
		if ($VMHost.HyperthreadingActive) {
			$HRow.CpuCoresPer = ($VMHost.ExtensionData.Hardware.CpuInfo.NumCpuCores)/($VMHost.ExtensionData.Hardware.CpuInfo.NumCpuPackages)
		} else {
			$HRow.CpuCoresPer = $VMHost.ExtensionData.Hardware.CpuInfo.NumCpuCores
		}

		$HRow.CpuTotalMhz = $VMHost.CpuTotalMhz
		$HRow.TotalMemory_GB = $VMHost.MemoryTotalGB
		$HRow.Mem_Usage_GB = $VMHost.MemoryUsageGB
        $HRow.NumofVMs = (Get-VM -Location $VMHost).count

	
        ## Create Row in Array ##
        $QuickHostInv += $HRow
    }


    ##  Export to CSV Per vCenter ##
    $QuickHostInv | sort -property @{Expression="ClusterName";Descending=$false},  @{Expression="HostName";Descending=$false} -Unique | Export-Csv ESXDashboard_$VCSvr.csv -NoTypeInformation 
    Disconnect-VIServer -Server * -Force:$true -Confirm:$false
}


# Concatenate all CSV files
 Get-Content .\ESXDashboard*.csv | add-content .\TempAll.csv

# Strip Duplicate Headers
 Import-Csv .\TempAll.csv | where {$_.vCenter -notcontains "vCenter"} | Export-Csv .\All_ESXDashboard.csv -NoTypeInformation

# Delete Temp File
 Remove-Item -Path .\TempAll.csv -Force

# Move Files to Archive Folder
 $DateStamp = get-date -Format "yyyy.MM.dd"

if (Get-ChildItem .\*.csv -ErrorAction SilentlyContinue) {
    New-Item -Path .\Reports -Name $DateStamp -ItemType Directory -Force -InformationAction SilentlyContinue  
    Move-Item -Path .\*.csv -Destination .\Reports\$DateStamp -Force
}
Invoke-Sqlcmd "EXEC Itreportdata.dbo.USPLoadHosttrackingDashBoard;" -ServerInstance "RCPONEMNT004" -username "svc_VropsLoader" -password "May81945" 