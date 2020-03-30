Get-VMHost -state NotResponding | foreach-object {
  $vmhost = $_
  $connectSpec = New-Object VMware.Vim.HostConnectSpec
  $connectSpec. force = $true
  $connectSpec. hostName = $vmhost.name
  $connectSpec. userName = 'root'
  $connectSpec. password = 'XXX'
  $vmhost. extensionData.ReconnectHost_Task( $connectSpec,$null )
}   
