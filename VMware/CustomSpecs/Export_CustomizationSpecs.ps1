# Export Customization Specs
$path = "."
$view = get-view CustomizationSpecManager
ForEach ($CustomizationProfile in $view.info) {
    $xml = $view.CustomizationSpecItemToXml($view.GetCustomizationSpec($CustomizationProfile.name))
    $xml | Out-File ($path + "\" + ($CustomizationProfile.name) + ".xml")
}
Disconnect-VIServer * -Confirm:$false
