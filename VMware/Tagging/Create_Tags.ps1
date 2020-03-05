function usage {
  echo ""
  write-host "Add-Tags.ps1 [-help] | [-v vCenterName] |  [-f InputCSVfile] " -foregroundcolor "white"
  echo ""
  write-host "-help prints this information" -foregroundcolor "white"
  echo ""
  write-host "-v specify a vCenter (optional)" -foregroundcolor "yellow"
  echo ""
  write-host "-f specify an input CSV file" -foregroundcolor "yellow"
  echo ""
  exit
}

#Set-Location D:\_Scripts\Misc

$vCSrvLst = @()

# check to see if we are using a file for input or if command-line arguments
if ("-v" -contains $args[0]) {
  $vCSrvLst=$args[1]
} else { 
    $vCSrvLst = "XXX"
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


# Adding PowerCLI core snapin
if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction silentlycontinue)) {
	add-pssnapin VMware.VimAutomation.Core
}

######## Main Section ########  
# Read in the CSV Data
$csvdata = Import-CSV $csvfile

$file = $null

$report = @()

foreach ($VCSvr in $vCSrvLst) {
	## Connect to vCenter
	connect-viserver "XXX"

	# Loop through each row in Input and Search for VM and Get Creation Info
	ForEach ($item in $csvdata) {
        $TagName = $item.Tag
        $CatName = $item.Category
        $Desc = $item.Description

        Write-host "Adding Tag:" $TagName " to vCenter: XXX"
        
        if ($null -eq $Desc) {
		    Get-TagCategory -Name $CatName | New-Tag -Name $TagName
        } 
        else
        {
            Get-TagCategory -Name $CatName | New-Tag -Name $TagName -Description $Desc
        }
    }
	Disconnect-VIServer -Server * -Force:$true -Confirm:$false
}