1..20 | Foreach-Object { Add-VMHost esx$_.corp.local -Location (Get-Datacenter DEV_SQL) -User root -Password <Password> -RunAsync -force:$true}
