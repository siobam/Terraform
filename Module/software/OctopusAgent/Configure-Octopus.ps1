param (
    $OctopusConnectionString = "${OctopusConnectionString}"
)
cd "C:\Program Files\Octopus Deploy\Tentacle"
# parse connection string
$octopusServerUrl = ($OctopusConnectionString.Split(';') | where {$_ -match "url"}).Split('=')[1].Trim()
$octopusAPIKey = ($OctopusConnectionString.Split(';') | where {$_ -match "key"}).Split('=')[1].Trim()
$octopusTHUMBPRINT = ($OctopusConnectionString.Split(';') | where {$_ -match "THUMBPRINT"}).Split('=')[1].Trim()
$octopusEnvironment = ($OctopusConnectionString.Split(';') | where {$_ -match "environment"}).Split('=')[1].Trim()
$octopusRole = ($OctopusConnectionString.Split(';') | where {$_ -match "role"}).Split('=')[1].Trim()
$ipV4 = (Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address).IPAddressToString  

function Get-OctopusInstallationStatus () {
# Powershell script to see if an octopus deploy tentacle is registered with an octopus deploy server
# Returns true if node is 'not' registered
# Replace 'http://octopus.example.com' and '1234578910' with your server and octopus deploy api key
    param (
       $OctopusUrl,
       $ApiKey
    ) 
    if (-not (test-path -path "C:\Program Files\Octopus Deploy\Tentacle\")) {
        throw "Octopus tentacl agent is not installed."
    }
    $ErrorActionPreference = 'SilentlyContinue'
    Push-Location "C:\Program Files\Octopus Deploy\Tentacle\"
    Add-Type -Path '.\Newtonsoft.Json.dll'
    Add-Type -Path '.\Octopus.Client.dll'
    $endpoint = new-object Octopus.Client.OctopusServerEndpoint $OctopusUrl, $ApiKey
    $repository = new-object Octopus.Client.OctopusRepository $endpoint
    $tentacle = New-Object Octopus.Client.Model.MachineResource
    $thumbprint = (& '.\Tentacle.exe' show-thumbprint --nologo --console)
    $thumbprint = $thumbprint -replace '.*([A-Z0-9]{40}).*', '$1'
    Pop-Location
    # if true - not installed
    $status = ([string]::IsNullOrEmpty($thumbprint) -OR $repository.Machines.FindByThumbprint($thumbprint).Thumbprint -ne $thumbprint)

    return $status
    $ErrorActionPreference = 'Continue'
}

# conigure Octopus agent
if (Get-OctopusInstallationStatus -OctopusUrl $octopusServerUrl -ApiKey $octopusAPIKey) {
    try {
        Write-Output "Install Octopus agent" 
        & .\Tentacle.exe create-instance --instance "Tentacle" --config "C:\Octopus\Tentacle.config" --console
        & .\Tentacle.exe new-certificate -e ("{0}\Tentacle.txt" -f $env:TEMP) --console
        & .\Tentacle.exe import-certificate --instance "Tentacle" -f ("{0}\Tentacle.txt" -f $env:TEMP) --console
        & .\Tentacle.exe configure --instance "Tentacle" --reset-trust --console
        & .\Tentacle.exe configure --instance "Tentacle" --home "C:\Octopus" --app "C:\Octopus\Applications" --port "10933" --console
        & .\Tentacle.exe configure --instance "Tentacle" --trust "$octopusTHUMBPRINT" --console
        & "netsh" advfirewall firewall add rule "name=Octopus Deploy Tentacle" dir=in action=allow protocol=TCP localport=10933
        & .\Tentacle.exe register-with --instance "Tentacle" `
                                    --server "$octopusServerUrl" --apiKey="$octopusAPIKey" --role "$octopusRole" --environment "$octopusEnvironment" `
                                    --publicHostName "$ipV4" `
                                    --comms-style TentaclePassive --console --force
        & .\Tentacle.exe service --instance "Tentacle" --install --start --console
        & sc.exe config "OctopusDeploy Tentacle" start=delayed-auto
        Stop-Service "OctopusDeploy Tentacle" -ErrorAction SilentlyContinue
        Start-Service "OctopusDeploy Tentacle"
    }catch {
        Throw "Failed to configure Octopus Tentacl agent."
    }

}

if (Get-OctopusInstallationStatus -OctopusUrl $octopusServerUrl -ApiKey $octopusAPIKey) {
    Throw "Unable to configure Octopus agent.$((Get-OctopusInstallationStatus -OctopusUrl $octopusServerUrl -ApiKey $octopusAPIKey))"
} else {
    Write-Output "Octopus has been configured."
}


