param (
      [Parameter(Mandatory = $true)]
      $VnetName,
      [Parameter(Mandatory = $true)]
      $ResourceGroup,
      [Parameter(Mandatory = $true)]
      $Location,
      [Parameter(Mandatory = $true)]
      $WebApp,
      [Parameter(Mandatory = $true)]
      $AADSecret,
      [Parameter(Mandatory = $true)]
      $AADClientID,
      [Parameter(Mandatory = $true)]
      $TenantID,
      [Parameter(Mandatory = $true)]
      $SubscriptionId,
      [Parameter(Mandatory = $true)]
      $AzureVPNClientPacakgeUrl 
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

$retry = 30
For ($i=0; $i -le $retry; $i++) { 
    Write-Output ("Join app service {0} to vnet ({1})...{2}\{3}" -f $WebApp,$VnetName, $retry,$i)
    try {
        New-AzureRmResource -Location $Location `
                            -Properties  @{ "vnetName" = $VnetName; "vpnPackageUri" = $AzureVPNClientPacakgeUrl } `
                            -ResourceName ("{0}/{1}/primary" -f $WebApp, $VnetName) `
                            -ResourceType "Microsoft.Web/sites/virtualNetworkConnections/gateways" `
                            -ApiVersion 2015-08-01 -ResourceGroupName $ResourceGroup -Force  *>$null
        $integrationState = $?
        if ($integrationState -eq $true) {
            Write-Output ("The app service {0} has been joined to vnet ({1})" -f $WebApp,$VnetName)
            break
        }
        start-sleep 5
    } catch {
        Write-Output ("Join app service {0} to vnet ({1})...[30\{2}]" -f $WebApp,$VnetName,$i)
    }
}
if ($integrationState -eq $false) {
    Throw ("An issue occured while joining  app service {0} to vnet ({1})" -f $WebApp,$VnetName)
} 
