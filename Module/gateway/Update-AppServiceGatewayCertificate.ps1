param (
    [Parameter(Mandatory = $true)]
    $AADSecret,
    [Parameter(Mandatory = $true)]
    $AADClientID,
    [Parameter(Mandatory = $true)]
    $TenantID,
    [Parameter(Mandatory = $true)]
    $GatewayId
)
Import-Module AzureRM.Websites
Import-Module AzureRM.Profile

$appServiceGwCertificateName = "AppServiceCertificate.cer"
$gatewayName = $GatewayId.split("/")[-1]
$subscriptionID = $GatewayId.split("/")[2]
$resourceGroup = $GatewayId.split("/")[4]
Function Add-GwAppServiceCertificate () {
    # return app service public certificate part.
    Param (
        $Gateway,
        $resourceGroupName
    )
    $appServiceCertificateName = "AppServiceCertificate.cer"
    try {
        $currentCertificate = Get-AzureRmVpnClientRootCertificate -VpnClientRootCertificateName $appServiceCertificateName `
                                                                  -VirtualNetworkgatewayName $gatewayName `
                                                                  -resourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
        if (!$currentCertificate) {
            $currentCertificate = $false
        }
        return  $currentCertificate.PublicCertData

    } catch {
        Throw "Unable to get app service certificate."
        exit 2
    }
}
# create sessiong for azure login
try {
    $securityString = $AADSecret | ConvertTo-SecureString -Force -AsPlainText
    $credential = New-Object System.Management.Automation.PsCredential("$AADClientID", $securityString)
    $session = Get-Credential -Credential $credential;
    # login to azure account
    Connect-AzureRmAccount -Credential $session `
                           -TenantId $TenantID `
                           -ServicePrincipal `
                           -Subscription $subscriptionID *>$null
} catch {
    throw "Azure authentication failed"
    exit 2
}
#-----------------------------------------------------------[Execution]------------------------------------------------------------
$gatewayProperties = Get-AzureRmVirtualNetworkGateway -ResourceGroupName $resourceGroup -Name $gatewayName
$networkId = ($gatewayProperties.IpConfigurations.subnet.id) -replace "/subnets/GatewaySubnet", ""
$networkName = $networkId.split('/')[-1]
$location = $gatewayProperties.location 

# check if app service certificate is on sync with gateway, get old certificate:
$oldAppServiceCertificate = Add-GwAppServiceCertificate -Gateway $gatewayName -resourceGroupName $resourceGroup

# Create temp app service plan and web app, integrate them to VNET, this action trigger certificate creation.
$appServiceName = ("{0}-{1}" -f $gatewayName, (Get-Random))
try {
    New-AzureRmAppServicePlan -resourceGroupName $resourceGroup `
                              -location $location `
                              -Tier Standard `
                              -Name $appServiceName *>$null

    New-AzureRmWebApp -resourceGroupName $resourceGroup `
                      -Name $appServiceName `
                      -location $location `
                      -AppServicePlan $appServiceName *>$null
    # integrate web app to vnet. THe certificate with name "AppServiceCertificate.cer" will be added automatically by Azure. 
    $appServiceVnetIntegration = New-AzureRmResource -location $location `
                                                     -Properties @{ "vnetResourceId" = "$networkId" } `
                                                     -ResourceName ("{0}/{1}" -f $appServiceName, $networkName) `
                                                     -ResourceType "Microsoft.Web/sites/virtualNetworkConnections" `
                                                     -ApiVersion 2015-08-01 `
                                                     -resourceGroupName $resourceGroup -Force  
    $newAppServiceCertificate = $appServiceVnetIntegration.Properties.CertBlob
} catch {
    Throw "Unable to create temp app plan and web app with vnet integration."
}
# check if gateway certificate need to be updated.
if ($oldAppServiceCertificate -ne $newAppServiceCertificate) {
    
    try { 
        # remove old certificate
        if ($oldAppServiceCertificate) {
            write-host "Remove AppServiceCertificate.cer from gateway. "
            Remove-AzureRmVpnClientRootCertificate -VpnClientRootCertificateName $appServiceGwCertificateName `
                                                   -PublicCertData $oldAppServiceCertificate.PublicCertData `
                                                   -VirtualNetworkgatewayName $gatewayName `
                                                   -resourceGroupName $resourceGroup 
        }
        # add new
        write-host "Add AppServiceCertificate.cer to gateway. "
        Add-AzureRmVpnClientRootCertificate -VpnClientRootCertificateName $appServiceGwCertificateName `
                                            -PublicCertData $newAppServiceCertificate `
                                            -VirtualNetworkgatewayName $gatewayName `
                                            -resourceGroupName $resourceGroup
    }catch {
        Throw "An error occured while updating certificate."
    }
} else {
    Write-Host "App service certificate is already synced with gateway. Script has been compleated successfully."
}
# remove temp resources
try {
    Remove-AzureRmWebApp -resourceGroupName $resourceGroup -Name $appServiceName -Force
    Remove-AzureRmAppServicePlan -resourceGroupName $resourceGroup -Name $appServiceName -Force
} catch {
    throw "Unable to remove temp script resoruces (app service plan and web app), please remove them manually."
}



