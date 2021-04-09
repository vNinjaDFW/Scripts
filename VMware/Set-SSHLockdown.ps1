# ***********************************************************************
# * Title:            Configure ESXi Host SSH & Lockdown
# * Purpose:          This script helps to Enable\Disable SSH & Lockdown Mode
# *                   for all hosts in a specified Cluster
# * Args:             vCenter, Cluster
# * Author:           Ryan Patel
# * Creation Date:    1/21/2017
# * Last Modified:    1/21/2017
# * Version:          1.0
# ***********************************************************************
$vCenter = Read-Host -Prompt 'Enter the FQDN of the vCenter Server you want to connect to:'

# This Try/Catch statement will stop the script if a vCenter Server doesn't exist, a bad username/password is entered, etc.
Try {
    Connect-VIServer -Server $vCenter -ErrorAction Stop | Out-Null
}

Catch {
    Write-Host -ForegroundColor Red -BackgroundColor Black "Could not connect to [$vCenter]." `n
    Exit
}

# Select the Cluster
Write-Host ""
Write-Host "Choose the Cluster you want to work with:" -BackgroundColor Yellow -ForegroundColor Black
Write-Host ""
$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster:"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"." -ForegroundColor Blue

# Get Hosts in the selected cluster
$vmHosts = Get-Cluster -Name $sCluster | Get-VMHost | Sort-Object

$cont = ""

Do {
	# Ask the user what step to perform
	Write-Host `n
	Write-Host "Enter the number of the Task you wish to perform:"
	Write-Host "1.) Enable SSH"
	Write-Host "2.) Disable SSH"
	Write-Host "3.) Enable Lockdown Mode"
	Write-Host "4.) Disable Lockdown Mode"
	Write-Host "5.) Exit" `n
	$choice = Read-Host

	# Perform a particular task based on user input
	Switch ($choice) {

		# If task #1 is chosen, Enable SSH on all hosts in the cluster
		1 {
			Write-Host -ForegroundColor Yellow `n "Enabling SSH on all hosts in the $sCluster cluster."
			ForEach ($vmHost in $vmHosts) {
				Start-VMHostService -HostService ($vmHost | Get-VMHostService | Where-Object {$_.key -eq "TSM-SSH"}) -Confirm:$false | Select-Object VMHost,Key,Label,Running
			}
		$cont = $true
		}
		# If task #2 is chosen, Disable SSH on all hosts in the cluster
		2 {
			Write-Host -ForegroundColor Yellow `n "Disabling SSH on all hosts in the $sCluster cluster."
			ForEach ($vmHost in $vmHosts) {
				Stop-VMHostService -HostService ($vmHost | Get-VMHostService | Where-Object {$_.key -eq "TSM-SSH"}) -Confirm:$false | Select-Object VMHost,Key,Label,Running
			}
			$cont = $true
		}

		# If task #3 is chosen, Enable Lockdown Mode on all hosts in the cluster
		3 {
			Write-Host -ForegroundColor Yellow `n "Enabling Lockdown Mode on all hosts in the $sCluster cluster."
			ForEach ($vmHost in $vmHosts) {
				($vmHost | Get-View).EnterLockdownMode()
			}
			$cont = $true
		}
		
		# If task #4 is chosen, Disable Lockdown Mode on all hosts in the cluster
		4 {
			Write-Host -ForegroundColor Yellow `n "Disabling Lockdown Mode on all hosts in the $sCluster cluster."
			ForEach ($vmHost in $vmHosts) {
				($vmHost | Get-View).ExitLockdownMode()
			}
			$cont = $true
		}

		# If task #5 is chosen, exit the script
		5 {
			Write-Host "Exiting..."
			$cont = $false
		}

		# If user enters anything other than 1-5, input is invalid and ask question again
		default {
			Write-Host -ForegroundColor Red ">>> Invalid input. Please select option 1-5."
			$cont = $true
		}
	}
}

# Loop through the script until task #5 (Exit) is chosen
While ($cont)

# Disconnect from the vCenter Server
Disconnect-VIServer -Server $vCenter -Confirm:$false | Out-Null
