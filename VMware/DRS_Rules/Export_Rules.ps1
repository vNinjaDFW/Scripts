# *******************************************************************
# * Title:            DRS Rules Exporter      
# * Purpose:          This script Exports DRS Rules for all Clusters.
# * Args:             vCenter
# * Author:           Ryan Patel
# * Creation Date:    09/01/2017
# * Last Modified:    09/01/2017
# * Version:          1.0
# *******************************************************************
# Get the list of vCenters
$vCenters = Get-Content "\\SERVER_NAME\ScriptLogs\vCenters.csv"

foreach ($vCenter in $vCenters)
{
Connect-VIServer $vCenter -WarningAction SilentlyContinue
$outpath = "\\SERVER_NAME\ScriptLogs\DRSRules\"
$outfile = $outpath + "Rules_" + $vCenter + ".csv"
$rules = Get-Cluster -server $vCenter | Get-DrsRule
$output=@()
if ($rules -ne $NULL)
{
 foreach($rule in $rules){
   $line=""|Select Cluster,Name,Enabled,KeepTogether,VM1,VM2
   $line.cluster = (Get-View -Id $rule.ClusterId).Name
   $line.name = $rule.Name 
   $line.Enabled = $rule.Enabled
   $line.KeepTogether = $rule.KeepTogether
   $line.VM1 = (get-view -id ($rule.VMIds)[0]).name
   $line.VM2 = (get-view -id ($rule.VMIds)[1]).name
   $output+=$line
 }
}
$output | Export-CSV -notypeinformation $outfile
Disconnect-VIServer $vCenter -Confirm:$false
}
