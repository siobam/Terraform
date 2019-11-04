# terrafrom data null_resoruce requirements
$userInput = [Console]::In.ReadLine()
$input = ConvertFrom-Json $userInput
$AADSecret = $input.AADSecret
$AADClientID = $input.AADClientID
$TenantID = $input.TenantID
$ResourceGroup = $input.ResourceGroup
$SubscriptionID = $input.SubscriptionID
$ResourceType = $input.ResourceType

try {
    $securityString = $AADSecret | ConvertTo-SecureString -Force -AsPlainText
    $credential = New-Object System.Management.Automation.PsCredential("$AADClientID", $securityString)
    $session = Get-Credential -Credential $credential;
    # login to azure account
    Connect-AzureRmAccount -Credential $session `
                           -TenantId $TenantID `
                           -ServicePrincipal `
                           -Subscription $SubscriptionID *>$null
} catch {
    throw "Azure authentication failed"
    exit 2
}
$targetResources = @()
switch ($ResourceType) {
    "database" { 
        $ResourceType = "Microsoft.Sql/servers/databases"
     }
    "app_service" {
        $ResourceType = "Microsoft.Web/sites"
    }
    "app_service_plan" {
        $ResourceType = "microsoft.web/serverfarms"
    }
    "virtual_machine" {
        $ResourceType = "Microsoft.Compute/virtualMachines"
    }
}
$resources = Get-AzureRmResource -ResourceType $ResourceType -ResourceGroupName $ResourceGroup

foreach($resource in ($resources  | select Name, ResourceId)) {
    $targetResources += ("{0}|{1}" -f $resource.Name,$resource.ResourceId)
}

return @"
{
    "resource": "$($targetResources -join ',')"
}
"@

