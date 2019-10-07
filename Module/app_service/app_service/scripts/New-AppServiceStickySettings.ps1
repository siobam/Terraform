param (
  [Parameter(Mandatory = $true)]
  $ResourceGroup,
  [Parameter(Mandatory = $true)]
  $Location,
  [Parameter(Mandatory = $true)]
  $WebApp,
  [Parameter(Mandatory = $true)]
  $WebAppSlot,
  [Parameter(Mandatory = $true)]
  $AADSecret,
  [Parameter(Mandatory = $true)]
  $AADClientID,
  [Parameter(Mandatory = $true)]
  $TenantID,
  [Parameter(Mandatory = $true)]
  $SubscriptionId
)
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
$appSettingName = "INACTIVE_DEPLOYMENT_SLOT"
# appsetting for web app slot
$slotAppSetting = @{}
$slotAppSetting["$appSettingName"] = "true"

# appsetting for web app 
$liveAppSetting = @{}
$liveAppSetting["$appSettingName"] = "false"
# create sticky setting
try {
  Set-AzureRmWebAppSlotConfigName -appSettingName $appSettingName -Name $WebApp -ResourceGroupName $ResourceGroup *>$null
} catch {
  throw "Unable to set app slot settings."
}

# set value for live and deployment slot
For ($i=0; $i -le 5; $i++) { 
  try {
    Write-Output ("Set app service settings:INACTIVE_DEPLOYMENT_SLOT=false (retry - 5\{0})" -f $i)
    $setLiveSetting = Set-AzureRmWebApp -ResourceGroupName $ResourceGroup -Name $WebApp -AppSettings $liveAppSetting
    if ($? -eq $true) 
    {
      $status = $?
      break
    }
    
  } catch {

  }
  start-sleep 5
}

For ($i=0; $i -le 5; $i++) { 
  try {
    Write-Output ("Set app service slot settings:INACTIVE_DEPLOYMENT_SLOT=true (retry - 5\{0})" -f $i)
    $setSlotSetting = Set-AzureRmWebAppSlot -ResourceGroupName $ResourceGroup -Name $WebApp -AppSettings $slotAppSetting -Slot $WebAppSlot
    if ($? -eq $true) 
    {
      $status = $?
      break
    }
  } catch {

  }
  start-sleep 5
}

if ($status -eq $false) {
  Throw "An error occured while creating stick settings for app service."
}
