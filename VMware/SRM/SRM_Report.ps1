<#
Export CSV report of all SRM protected VMs in a vCenter with their corresponding Protection Groups
#>

$credential = Get-Credential
$vcenter = 'Protected_vCenter'
Connect-VIServer $vcenter -WarningAction:SilentlyContinue
$srm = Connect-SrmServer -Credential $credential -RemoteCredential $credential
$outputdir = $env:USERPROFILE + "\Desktop\SRMVMReport\"
$test = Test-Path $outputdir
IF (!$test){MKDIR $outputdir | out-null}
$date = Get-Date -Format MMMddyyyy_hhmm
$filename = $outputdir + $vcenter +"_SRMVMReport_" + $date + ".csv" 

$srmApi = $srm.ExtensionData
$protectionGroups = $srmApi.Protection.ListProtectionGroups()
$srmvms = @()
$srmdss = @()

foreach ($protectionGroup in $protectionGroups){
    $protectionGroupInfo = $protectionGroup.GetInfo()
    $protectedVms = $protectionGroup.ListProtectedVms()
    $protectedVms | % { $_.Vm.UpdateViewData() }
    $protectedVms | %{
        $output = "" | select VmName, PgName
        $output.VmName = $_.Vm.Name
        $output.PgName = $protectionGroupInfo.Name
        $srmvms += $output
    }
    $protectedDss = $protectionGroup.ListProtectedDatastores()
    $protectedDss | % { $_.UpdateViewData() }
    $protectedDss | %{
        $output = "" | select DsName, PgName
        $output.DsName = $_.Name
        $output.PgName = $protectionGroupInfo.Name
        $srmdss += $output
    }
}

#VM Tags
foreach ($vm in $srmvms){
    IF ($vm.PgName){    
        IF (!(Get-Tag $vm.PgName -Category "SRM Protection Group" -ErrorAction:SilentlyContinue)){
            New-Tag -Name $vm.PgName -Category "SRM Protection Group" | Out-Null
        } 
        Get-VM $vm.VmName | New-TagAssignment -Tag $vm.PgName | Out-Null
    }
}

#DS Tags
foreach ($ds in $srmdss){
    IF ($ds.PgName){    
        IF (!(Get-Tag $ds.PgName -Category "SRM Protection Group" -ErrorAction:SilentlyContinue)){
            New-Tag -Name $ds.PgName -Category "SRM Protection Group" | Out-Null
        } 
        Get-Datastore $ds.DsName | New-TagAssignment -Tag $ds.PgName | Out-Null
    }
}

#Disconnect-SrmServer * -Confirm:$false
#Disconnect-VIServer * -Confirm:$false
