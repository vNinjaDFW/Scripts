# Import Customization Specs
$path = "."
$view = Get-View CustomizationSpecManager
ForEach ($xmlfile in (Get-ChildItem -Path $path | where {$_.extension -eq ".xml"})) {
    $xml = Get-Content ($xmlfile)
    $view.CreateCustomizationSpec($view.XmlToCustomizationSpecItem($xml))
}
Disconnect-VIServer * -Confirm:$false
