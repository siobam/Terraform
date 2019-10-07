param (
      $GatewayName,
      $ResourceGroup,
      $AADSecret,
      $AADClientID,
      $TenantID,
      $SubscriptionId
)
# use this variable to determin the web app integration state
$integrationState = $false
try {
    $securityString = $AADSecret | ConvertTo-SecureString -Force -AsPlainText
    $credential = New-Object System.Management.Automation.PsCredential("$AADClientID", $securityString)
    $session = Get-Credential -Credential $credential;
    # login to azure account
    Connect-AzureRmAccount -Credential $session `
                           -TenantId $TenantID `
                           -ServicePrincipal `
                           -Subscription $SubscriptionId *>$null
} catch {
    throw "Azure authentication failed"
    exit 2
}
$certificates = Get-AzureRmVpnClientRootCertificate -VirtualNetworkgatewayName $GatewayName `
                                                    -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue  
if ($certificates) {
    $vpnClient = Get-AzureRmVpnClientPackage -ResourceGroupName $ResourceGroup `
                                             -VirtualNetworkGatewayName $GatewayName `
                                             -ProcessorArchitecture Amd64 -ErrorAction SilentlyContinue
} else {
    $vpnClient = "null"
}

$result = @"
{
    "vpn": $vpnClient
}
"@
return $result