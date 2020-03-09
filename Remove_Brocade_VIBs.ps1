# *******************************************************************
# * Title:            Remove Broacade VIBs
# * Purpose:          This script will remove Broacade VIBs from any host
# *                   in a cluster that is currently in Maintenance Mode
# * Author:           Ryan Patel
# * Creation Date:    06/11/2018
# * Last Modified:    06/11/2018 
# * Version:          1.0
# * Update Log:
# *    
# *******************************************************************

# Enter the name of a Cluster
[string]$Cluster = (Read-Host "Please enter the name of the Cluster:")

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

#Get list of hosts in cluster
$vmhosts = Get-Cluster $Cluster | Get-VMHost | Where-Object {$_.ConnectionState -eq "maintenance"}

#Define VIBs
$vibs = @("brocade-esx50-bcu-plugin","hostprofile-bfaConfig","net-bna")

#Configuration Changes
foreach ($vmhost in $vmhosts){
    Write-host "Working on Host: $vmhost"
    $esxcli = get-esxcli -vmhost $vmhost
    foreach ($vib in ($vibs)) {
    write-host "      searching for vib $vib" -ForegroundColor Cyan
        if ($esxcli.software.vib.get.invoke() | where {$_.name -eq "$vib"} -erroraction silentlycontinue )  {
            write-host "      found vib $vib. Deleting" -ForegroundColor Green
            $esxcli.software.vib.remove.invoke($null, $true, $false, $true, "$vib") 
        } else {
            write-host "      vib $vib not found. continuing..." -ForegroundColor Yellow
        }
    }
}

#Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false
