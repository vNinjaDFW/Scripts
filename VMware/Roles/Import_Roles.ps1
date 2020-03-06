 <#   
  .Synopsis   
   Imports roles into vsphere roles..   
  .Description   
   This script imports roles into vspheres from .role file/   
  .Example   
   Import-vSphereRoles -Path c:\temp  
   Import Roles to the folder.   
  .Notes  
   NAME: Import-vSphereRoles   
   AUTHOR: Kunal Udapi   
   LASTEDIT: 15th February 2016  
   KEYWORDS: Import Roles   
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
   $roleFiles = Get-ChildItem -Path $Path -Filter *.role  
 }  
 Process {  
   foreach ($role in $roleFiles) {  
     $VIRoleName = $role.BaseName   
     $RolesContent = Get-Content -Path $role.FullName  
     New-Virole -Name $VIRoleName | Out-Null  
     Write-Host "Created Role `"$VIRoleName`"" -BackgroundColor DarkGreen  
     foreach ($Privilege in $RolesContent) {  
       if (-not($privilege -eq $null -or $privilage -eq "")) {  
         Write-Host "Setting Permissions `"$Privilege`" on Role `"$VIRoleName`"" -ForegroundColor Yellow  
         Set-VIRole -Role $VIRoleName -AddPrivilege (Get-VIPrivilege -ID $privilege) | Out-Null  
       } #if (-not($privilege -eq $null -or $privilage -eq ""))  
     } #foreach ($Privilege in $RolesContent)  
   } #foreach ($role in $roleFiles)  
 }
