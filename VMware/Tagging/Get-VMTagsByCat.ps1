$vCSrvLst = @()

if ("-v" -contains $args[0]) {
  $vCSrvLst=$args[1]
} else { 
    $vCSrvLst = "XXX"
}

$file = $null
$report = @()

foreach ($VCSvr in $vCSrvLst) {
	## Connect to vCenter
	Connect-viserver "XXX"
    $report = @()
    $TagCats = Get-TagCategory

	# Loop through each row in Input and Search for VM and Get Creation Info
	ForEach ($TCat in $TagCats) {
        $TCatName = $TCat
        write-host Exporting list of VMs assigned to Tag Category: $TCatName
        $AssignedTags = Get-TagAssignment -Category $TCatName -ErrorAction SilentlyContinue

		ForEach ($ATag in $AssignedTags) {
            $row = "" | select VMName, Tag
            $row.VMName = $ATag.Entity.Name
            $row.Tag = $ATag.Tag
            $report += $row
        }
	}
    $report | sort -property @{Expression="VMName";Descending=$false} | Export-Csv TaggedVMs_$VCSvr.csv -NoTypeInformation 
    Disconnect-VIServer -Server * -Force:$true -Confirm:$false
}
