<#   
  .Synopsis   
   Exports vsphere roles to text file extension roles.   
  .Description   
   This script exports only the custom created roles by users   
  .Example   
   Export-vSphereRoles -Path c:\temp  
   Exports Roles to the folder.   
  .Notes  
   NAME: Export-vSphereRoles   
   AUTHOR: Kunal Udapi   
   LASTEDIT: 12th February 2016  
   KEYWORDS: Export Roles   
  .Link   
   #Check Online version: http://kunaludapi.blogspot.com    
   #Requires -Version 3.0   
  #>   
  #requires -Version 3    
 [CmdletBinding(SupportsShouldProcess)]   
  Param(   
   [Parameter(Mandatory=$true, Position=1,   
    ValueFromPipeline=$true)]   
   [AllowNull()]   
   [alias("LiteralPath")]   
   [string]$Path = "c:\temp"    
  ) #Param   
 Begin {  
   $DefaultRoles = "NoAccess", "Anonymous", "View", "ReadOnly", "Admin", "VirtualMachinePowerUser", "VirtualMachineUser", "ResourcePoolAdministrator", "VMwareConsolidatedBackupUser", "DatastoreConsumer", "NetworkConsumer"  
   $DefaultRolescount = $defaultRoles.Count  
   $CustomRoles = @()  
 } #Begin  
   
 Process {  
   $AllVIRoles = Get-VIRole  
   
   0..($DefaultRolescount) | ForEach-Object {  
     if ($(Get-Variable "role$_" -ErrorAction SilentlyContinue)) {  
       Remove-Variable "role$_" -Force -Confirm:$false  
     } #if ($(Get-Variable "role$_" -ErrorAction SilentlyContinue))  
   } #0..($DefaultRolescount) | Foreach-Object  
   
   0..$DefaultRolescount | ForEach-Object {  
     $DefaultRolesnumber = $DefaultRoles[$_]  
     if ($_ -eq 0) {  
       New-Variable "role$_" -Option AllScope -Value ($AllVIRoles | Where-Object {$_.Name -ne $DefaultRolesnumber})  
     } #if ($_ -eq 0)  
     else {  
       $vartxt = $_ - 1  
       $lastrole = 'role'+"$vartxt"  
       #Get-Variable $lastrole  
       New-Variable "role$_" -Option AllScope -Value (Get-Variable "$lastrole" | select -ExpandProperty value | Where-Object {$_.Name -ne $DefaultRolesnumber})  
     } #else ($_ -eq 0)  
   } #0..$DefaultRolescount | ForEach-Object  
   $filteredRoles = Get-Variable "role$($DefaultRolescount-1)" | select -ExpandProperty value  
 } #Process  
 End {  
   $filteredRoles | ForEach-Object {  
     $completePath = Join-Path -Path $Path -ChildPath "$_.role"  
     Write-Host "Exporting Role `"$($_.Name)`" to `"$completePath`"" -ForegroundColor Yellow  
     $_ | Get-VIPrivilege | select-object -ExpandProperty Id | Out-File -FilePath $completePath  
   } #$filteredRoles | ForEach-Object  
 } #End
