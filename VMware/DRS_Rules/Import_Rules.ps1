# *******************************************************************
# * Title:            DRS Rules Importer      
# * Purpose:          This script Imports DRS Rules for all Clusters.
# * Args:             vCenter
# * Author:           Ryan Patel
# * Creation Date:    09/01/2017
# * Last Modified:    09/01/2017
# * Version:          1.0
# *******************************************************************
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

# Open File Dialog Function
function Select-FileDialog
{
	param([string]$Title,[string]$Directory,[string]$Filter="All Files (*.*)|*.*")
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	$objForm = New-Object System.Windows.Forms.OpenFileDialog
	$objForm.InitialDirectory = $Directory
	$objForm.Filter = $Filter
	$objForm.Title = $Title
	$Show = $objForm.ShowDialog()
	If ($Show -eq "OK")
	{
		Return $objForm.FileName
	}
	Else
	{
		Write-Error "Operation cancelled by user."
	}
}

# Import DRS Rules
$rules = Select-FileDialog -Title "Select the CSV file to Import"
if($rules -eq $NULL){throw "Could not read $rules"}

$clusters=$rules|select cluster|sort cluster|Get-Unique -AsString|%{$_.cluster}
foreach ($cluster in $clusters)
{
 $clusterrules = $rules|?{$_.cluster -eq $cluster}
 $clusterobj=get-cluster $cluster
 foreach ($rule in $clusterrules)
 {new-drsrule -cluster $clusterobj -Name $rule.name -Enabled ([system.convert]::toBoolean($rule.enabled)) `
  -KeepTogether ([system.convert]::toBoolean($rule.keeptogether)) -VM (get-vm $rule.vm1,$rule.vm2)} 
}

# Disconnect from vCenter
Disconnect-VIServer $vcenter -confirm:$false
