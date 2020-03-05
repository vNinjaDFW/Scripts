# Select the Cluster
Write-Host ""
Write-Host "Choose the Cluster:" -BackgroundColor Yellow -ForegroundColor Black
Write-Host ""
$iCluster = Get-Cluster | Select Name | Sort-object Name
$i = 1
$iCluster | %{Write-Host $i":" $_.Name; $i++}
$dCluster = Read-Host "Enter the number for the Cluster:"
$sCluster = $iCluster[$dCluster -1].Name
Write-Host "You picked:" $sCluster"." -ForegroundColor Blue

$Collection = @()  
 
#$Esxihosts = Get-Datacenter $sCluster | Get-VMHost
$Esxihosts = Get-Cluster $sCluster | Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"}
foreach ($Esxihost in $Esxihosts) {  
   $Esxcli = Get-EsxCli -VMHost $Esxihost  
   $Esxihostview = Get-VMHost $EsxiHost | get-view  
   $NetworkSystem = $Esxihostview.Configmanager.Networksystem  
   $Networkview = Get-View $NetworkSystem  
       
   $DvSwitchInfo = Get-VDSwitch -VMHost $Esxihost  
   if ($DvSwitchInfo -ne $null) {  
     $DvSwitchHost = $DvSwitchInfo.ExtensionData.Config.Host  
     $DvSwitchHostView = Get-View $DvSwitchHost.config.host  
     $VMhostnic = $DvSwitchHostView.config.network.pnic  
     $DVNic = $DvSwitchHost.config.backing.PnicSpec.PnicDevice  
   }  
     
   $VMnics = $Esxihost | get-vmhostnetworkadapter -Physical   #$_.NetworkInfo.Pnic  
   Foreach ($VMnic in $VMnics){  
       $realInfo = $Networkview.QueryNetworkHint($VMnic)  
       $pNics = $esxcli.network.nic.list() | where-object {$vmnic.name -eq $_.name} | Select-Object Description, Link           
       $Description = $esxcli.network.nic.list()  
       $CDPextended = $realInfo.connectedswitchport  
         if ($vmnic.Name -eq $DVNic) {  
             
           $vSwitch = $DVswitchInfo | where-object {$vmnic.Name -eq $DVNic} | select-object -ExpandProperty Name  
         }  
         else {  
           $vSwitchname = $Esxihost | Get-VirtualSwitch | Where-object {$_.nic -eq $VMnic.DeviceName}  
           $vSwitch = $vSwitchname.name  
         }  
   $CDPdetails = New-Object PSObject  
   $CDPdetails | Add-Member -Name EsxName -Value $esxihost.Name -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name VMNic -Value $VMnic -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name vSwitch -Value $vSwitch -MemberType NoteProperty  
   $CDPdetails | Add-Member -Name Link -Value $pNics.Link -MemberType NoteProperty   
   $CDPdetails | Add-Member -Name Switch-IP -Value $CDPextended.Address -MemberType NoteProperty  
   $collection += $CDPdetails  
   }  
 }  
   
$Collection | Export-CSV C:\Temp\$sCluster.csv -NoTypeInformation
