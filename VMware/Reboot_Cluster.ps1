# *******************************************************************
# * Title:            Reboot Cluster      
# * Purpose:          This script reboots Hosts in the specified
# *					  Cluster one at a time.
# * Args:             vCenter & Cluster Name
# * Author:           Ryan Patel
# * Creation Date:    12/07/2017
# * Last Modified:    12/07/2017
# * Version:          1.0
# *******************************************************************
# Check for valid command
if ($args.count -ne 2) {
Write-Host "Usage: Reboot-Cluster.ps1 <vCenter> <Cluster Name>"
Exit
}
 
# Set vCenter and Cluster name from Arg
$vCenterServer = $args[0]
$ClusterName = $args[1]

# Connect to vCenter
Connect-VIServer -Server $vCenterServer -WarningAction SilentlyContinue

# Get Hosts in Cluster
$ESXiServers = @(Get-Cluster $ClusterName | Get-VMHost)

Function RebootESXiServer ($CurrentServer) {
$ServerName = $CurrentServer.Name

# Place Host in Maintenance Mode
Set-VMHost $CurrentServer -state Maintenance -Evacuate | Out-Null

# Reboot Host
Write-Host "Rebooting"
Restart-VMHost $CurrentServer -confirm:$false | Out-Null
 
# Wait for Server to show as down
do {
sleep 15
$ServerState = (get-vmhost $ServerName).ConnectionState
}
while ($ServerState -ne "NotResponding")
Write-Host "$ServerName is Down"
 
# Wait for server to reboot
do {
sleep 60
$ServerState = (get-vmhost $ServerName).ConnectionState
Write-Host "Waiting for Reboot ..."
}
while ($ServerState -ne "Maintenance")
Write-Host "$ServerName is back up"
 
# Exit maintenance mode
Write-Host "Exiting Maintenance mode"
Set-VMhost $CurrentServer -State Connected | Out-Null
Write-Host "#### Reboot Complete####"
Write-Host ""
}
 
# MAIN
foreach ($ESXiServer in $ESXiServers) {
RebootESXiServer ($ESXiServer)
}

# Disconnect from vCenter
Disconnect-VIServer $vCenter -confirm:$false
