
$Application = "Octopus Deploy Tentacle"
$tentacleUrl = "https://download.octopusdeploy.com/octopus/Octopus.Tentacle.3.22.0-x64.msi"
$outputFile = "D:\Octopus.Tentacle.msi"
function Get-InstalledApps{
    If ([IntPtr]::Size -eq 4) {
        $regpath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
    Else{
        $regpath = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
    }
    Get-ItemProperty $regpath | .{process{If($_.DisplayName -and $_.UninstallString) { $_ } }} | Select-Object DisplayName, Publisher, InstallDate, DisplayVersion, UninstallString | Sort-Object DisplayName
}
$result = Get-InstalledApps | Where-Object {$_.DisplayName -like $Application}

If ($result -eq $null) {
    try {
        Write-Host ("{0}: Download and install..." -f (get-date -Format ("yyyy:MM:dd hh:mm:ss")))
        [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
        (New-Object System.Net.WebClient).DownloadFile($TentacleUrl, $OutputFile)
        msiexec /i $outputFile /quiet
        Start-Sleep -s 3
        Write-Host ("{0}: {1} has been installed" -f (get-date -Format ("yyyy:MM:dd hh:mm:ss")), $Application)
    } catch {
        throw "An issue occured while installing Octopus agent on node."
    }
}
Else {
    Write-Host ("{0}: {1} Already installed" -f (get-date -Format ("yyyy:MM:dd hh:mm:ss")), $Application)
}
