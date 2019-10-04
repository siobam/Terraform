param (
    $CrossTenantAADClientId,
    $CrossTenantAADClientSecret,
    $TargetTenant,
    $TargetNetworkId,
    $RemoteTenant,
    $RemoteNetworkId,
    $TargetPpeeringName,
    $RemotePeeringName,
    $TargetNetworkPeering,
    $RemoteNetworkPeering
)
# get network name and subscription id from network id.
$targetSubscriptionId = $TargetNetworkId.split('/')[2]
$targetVnetName = $TargetNetworkId.split('/')[-1]
$targetResourceGroup = $TargetNetworkId.split('/')[4]

$remoteVnetName = $RemoteNetworkId.split('/')[-1]
$remoteResourceGroup = $RemoteNetworkId.split('/')[4]
$remoteSubscriptionId = $RemoteNetworkId.split('/')[2]
Function Login-Azure () {
    param (
        $ClientId,
        $Secret,
        $Tenant,
        $Subscription
    )
    $securityString = $Secret | ConvertTo-SecureString -Force -AsPlainText
    $credential = New-Object System.Management.Automation.PsCredential("$ClientId",$securityString)
    $session = Get-Credential -Credential $credential;
    try {
        Connect-AzAccount -Credential $session -TenantId $Tenant -ServicePrincipal -Subscription $Subscription
    } catch {
        Write-Output "An issue occured while trying to login to azure portal "
    }
}
Function Validate-Peering () {
    Param (
        $NetworkPeerings = ($TargetNetworkPeering),
        $RemoteNetworkId = $RemoteNetworkId,
        $PeeringName = $TargetPpeeringName
    )

    if ($NetworkPeerings -ne $null) { 
        $NetworkPeerings = $NetworkPeerings
    }
    $peering = ""
    foreach($peer in $NetworkPeerings.psobject.Members ) {
        if ($peer.Value -eq $RemoteNetworkId) {
            $peering = $peer
            break
        }
    }
    if ($peering) {
        if ($peering.name -eq $PeeringName) {
            $state = $true
        } else {
            $state = $false
        }
    } else {
        $state = $false
    }
    return $state,$peering
}

$loginToTargetTenant = {
    Login-Azure -ClientId $CrossTenantAADClientId `
                -Secret $CrossTenantAADClientSecret `
                -Tenant $TargetTenant `
                -Subscription $targetSubscriptionId
}
$loginToRemoteTenant = {
    Login-Azure -ClientId $CrossTenantAADClientId `
                -Secret $CrossTenantAADClientSecret `
                -Tenant $RemoteTenant `
                -Subscription $RemoteSubscriptionId
}

Invoke-Command -ScriptBlock $loginToTargetTenant
# login azure rm account for target network
$targetNetwork = (Get-AzVirtualNetwork -Name $targetVnetName -ResourceGroupName $targetResourceGroup)

# login azure rm account for remote network
Invoke-Command -ScriptBlock $loginToRemoteTenant
$remoteNetwork = (Get-AzVirtualNetwork -Name $remoteVnetName -ResourceGroupName $remoteResourceGroup)
 
$checkTargetPeering = Validate-Peering -NetworkPeerings ("$TargetNetworkPeering" | ConvertFrom-Json) -RemoteNetworkId $RemoteNetworkId -PeeringName $TargetPpeeringName
$checkRemotePeering = Validate-Peering -NetworkPeerings ("$RemoteNetworkPeering" | ConvertFrom-Json) -RemoteNetworkId $TargetNetworkId -PeeringName $RemotePeeringName
#throw "$TargetNetworkPeering"
# remote peering in case if it not valide.
if (($checkTargetPeering[0] -eq $false) -or ($checkRemotePeering[0] -eq $false) ) {
    Invoke-Command -ScriptBlock $loginToTargetTenant
    if ($checkTargetPeering[1]) {
        try {
            Remove-AzVirtualNetworkPeering -VirtualNetworkName $targetVnetName -Name $checkTargetPeering[1].name -ResourceGroupName $targetResourceGroup -Force
        } catch {
            throw ("An issue occured while removing peering - {0}" -f $TargetPpeeringName )
        }
    }
    Invoke-Command -ScriptBlock $loginToRemoteTenant
    if ($checkRemotePeering[1]) { 
        try {
            Remove-AzVirtualNetworkPeering -VirtualNetworkName $remoteVnetName -Name $checkRemotePeering[1].name -ResourceGroupName $remoteResourceGroup -Force
        } catch {
            throw ("An issue occured while removing peering - {0}" -f $RemotePeeringName )
        }
    }
    try {
        Invoke-Command -ScriptBlock $loginToTargetTenant
        Add-AzVirtualNetworkPeering -Name $TargetPpeeringName `
                                    -VirtualNetwork $targetNetwork  `
                                    -RemoteVirtualNetworkId $RemoteNetworkId
        $targetPeeringState = Get-AzVirtualNetworkPeering -Name $TargetPpeeringName `
                                                          -VirtualNetworkName $targetNetwork.Name `
                                                          -ResourceGroupName $targetNetwork.ResourceGroupName
        if (!$targetPeeringState) {
            Throw ("Peering does not exist - {0}" -f $TargetPpeeringName)
        }
    } catch {
        throw ("An issue occured while peering creation - {0}" -f $TargetPpeeringName )
    }

    
    try {
        Invoke-Command -ScriptBlock $loginToRemoteTenant
        Add-AzVirtualNetworkPeering -Name $RemotePeeringName `
                                    -VirtualNetwork $remoteNetwork `
                                    -RemoteVirtualNetworkId $TargetNetworkId
        $remotePeeringState = Get-AzVirtualNetworkPeering -Name $RemotePeeringName `
                                                          -VirtualNetworkName $remoteNetwork.Name `
                                                          -ResourceGroupName $remoteNetwork.ResourceGroupName
        if (!$remotePeeringState) {
            Throw ("Peering does not exist - {0}" -f $RemotePeeringName)
        }
    } catch {
        throw ("An issue occured while peering creation - {0}" -f $RemotePeeringName )
    }
} 

