$sCluster = (Read-Host "Please enter the name of the Cluster:")
Get-Cluster $sCluster | Get-Datastore | Select Name, @{N="NumVM";E={@($_ | Get-VM).Count}} | FT -AutoSize