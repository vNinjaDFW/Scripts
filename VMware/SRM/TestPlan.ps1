Import-Module \\SERVER\PowerCLI_Scripts\MeadowCraft\Meadowcroft.Srm.psd1
$credential = Get-Credential
Connect-VIServer -Server RECOVERY_SERVER -Credential $credential
Connect-SrmServer -Credential $credential -RemoteCredential $credential
CLS

# SaaS
Get-Date -DisplayHint Time
Get-SrmRecoveryPlan -Name "First_Plan" | Start-SrmRecoveryPlan -RecoveryMode Test -Confirm:$false
