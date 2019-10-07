param (
    [Parameter(Mandatory = $true)]
    $CNAME,
    [Parameter(Mandatory = $true)]
    $Domain,
    [Parameter(Mandatory = $true)]
    $GoDaddyAPIKey,
    [Parameter(Mandatory = $true)]
    $GoDaddyAPISecret,
    [Parameter(Mandatory = $true)]
    $AADSecret,
    [Parameter(Mandatory = $true)]
    $AADClientID,
    [Parameter(Mandatory = $true)]
    $TenantID,
    [Parameter(Mandatory = $true)]
    $WebAppName,
    [Parameter(Mandatory = $true)]
    $ResourceGroup,
    [Parameter(Mandatory = $true)]
    $Thumbprint,
    [Parameter(Mandatory = $true)]
    $SubscriptionID
)

IF ($CNAME.Length -ne 0) {
    #----------------------------------------------------------[Declarations]----------------------------------------------------------
    $headers = @{}
    $headers["Authorization"] = 'sso-key ' + $GoDaddyAPIKey + ':' + $GoDaddyAPISecret
    $body = ConvertTo-Json (@{name=$CNAME;data="$WebAppName.azurewebsites.net";ttl=600;type='CNAME'})

    $securityString = $AADSecret | ConvertTo-SecureString -Force -AsPlainText
    $credential = New-Object System.Management.Automation.PsCredential("$AADClientID",$securityString)
    $session = Get-Credential -Credential $credential;
    $PropertiesObject = @{"vnetResourceId" = "$VnetId" }
    #-----------------------------------------------------------[Execution]------------------------------------------------------------
    $aliase = (Invoke-WebRequest ("https://api.godaddy.com/v1/domains/{0}/records/CNAME/{1}" -f $Domain,"$CNAME") -Method Get -Headers $headers -UseBasicParsing).Content

    if ($aliase.Length -le 3) {
        $createGoDaddyRecord = Invoke-WebRequest ("https://api.godaddy.com/v1/domains/{0}/records/" -f $Domain) -Method PATCH `
                                                                                                              -Headers $headers `
                                                                                                              -ContentType "application/json" `
                                                                                                              -Body "[$body]" `
                                                                                                              -UseBasicParsing
        start-sleep -second 300
    }
    # bind hostname to web app
    Connect-AzureRmAccount -Credential $session -TenantId $TenantID -ServicePrincipal -Subscription $SubscriptionID *>$null
    Write-Host ("Add a custom domain name to the web app ({0}={1})" -f $WebAppName,("{0}.{1}" -f $CNAME,$Domain))
    # Add a custom domain name to the web app. 
    $setDns = Set-AzureRmWebApp -Name $WebAppName `
                                -ResourceGroupName $ResourceGroup `
                                -HostNames @(("{0}.{1}" -f $CNAME,$Domain),"$WebAppName.azurewebsites.net")

    IF ($Thumbprint.Length -ne 0) {
      # Upload and bind the SSL certificate to the web app.
      Write-Host ("Upload and bind the SSL certificate to the web app. ({0}={1})" -f $WebAppName,$Thumbprint)
      $setSsl = New-AzureRmWebAppSSLBinding -WebAppName $WebAppName `
                                            -ResourceGroupName $ResourceGroup `
                                            -Name ("{0}.{1}" -f $CNAME,$Domain) `
                                            -Thumbprint "$Thumbprint" `
                                            -SslState SniEnabled
    }
}