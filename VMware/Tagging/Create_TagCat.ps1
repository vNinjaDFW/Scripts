function usage {
  echo ""
  write-host "Add-TagCategories.ps1 [-help] | [-v vCenterName] |  [-f InputCSVfile] " -foregroundcolor "white"
  echo ""
  write-host "-help prints this information" -foregroundcolor "white"
  echo ""
  write-host "-v specify a vCenter (optional)" -foregroundcolor "yellow"
  echo ""
  write-host "-f specify an input CSV file" -foregroundcolor "yellow"
  echo ""
  exit
}

$vCSrvLst = @()

# check to see if we are using a file for input or if command-line arguments
if ("-v" -contains $args[0]) {
  $vCSrvLst=$args[1]
} else { 
    $vCSrvLst = "XXXX"
    # check to see if we are using a file for input or if command-line arguments
	if ("-f" -contains $args[0]) {
	  $csvfile=$args[1]
	} else { 
	    usage
	}

}

if ("-f" -contains $args[2]) {
  $csvfile=$args[3]
} 

######## Main Section ########  
# Read in the CSV Data
$csvdata = Import-CSV $csvfile

$file = $null

$report = @()

foreach ($VCSvr in $vCSrvLst) {
	## Connect to vCenter
	Connect-viserver "XXX"

	# Loop through each row in Input and Search for VM and Get Creation Info
	ForEach ($item in $csvdata) {
        $CatName = $item.Category
        $Card = $item.Cardinality
        # $Desc = '"{0}"' -f $item.Description
        $Desc = $item.Description

        Write-host "Adding Category:" $CatName " to vCenter: XXX"
        write-host $Desc

        write-host "New-TagCategory -Name $CatName -Cardinality $Card -Description $Desc -EntityType "VirtualMachine""
        New-TagCategory -Name $CatName -Cardinality $Card -Description $Desc -EntityType "VirtualMachine"

	}
	Disconnect-VIServer -Server * -Force:$true -Confirm:$false
}
