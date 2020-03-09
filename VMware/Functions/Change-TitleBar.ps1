Function Change-TitleBar() {
    ## check to see if there are any currently connected servers
    if ($global:DefaultVIServers.Count -gt 0) {
        ## since there is at least one connected server, modify the window title variable accordingly
        $strWindowTitle = "[PowerCLI] Connected to {0} server{1}:  {2}" -f $global:DefaultVIServers.Count, $(if ($global:DefaultVIServers.Count -gt 1) {"s"}), (($global:DefaultVIServers | %{$_.Name}) -Join ", ")
    }
    else {
        ## since there are no connected servers, modify the window title variable to show "not connected"
        $strWindowTitle = "[PowerCLI] Not Connected"
    }
    ## perform the window title change
    $host.ui.RawUI.WindowTitle = $strWindowTitle
}
