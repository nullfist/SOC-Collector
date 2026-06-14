param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "SystemInfo"
$CsvOut = Join-Path -Path $OutDir -ChildPath "InstalledSoftware.csv"

Write-Log -Level "INFO" -Message "Collecting Installed Software..."

try {
    $SoftwareList = @()
    
    # 32-bit and 64-bit paths
    $UninstallPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($Path in $UninstallPaths) {
        $Items = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
        foreach ($Item in $Items) {
            if ($Item.DisplayName) {
                $SoftwareList += [PSCustomObject]@{
                    DisplayName = $Item.DisplayName
                    DisplayVersion = $Item.DisplayVersion
                    Publisher = $Item.Publisher
                    InstallDate = $Item.InstallDate
                    InstallLocation = $Item.InstallLocation
                    UninstallString = $Item.UninstallString
                    RegPath = $Item.PSPath
                }
            }
        }
    }

    $SoftwareList | Sort-Object DisplayName -Unique | Export-Csv -Path $CsvOut -NoTypeInformation

} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Installed Software: $_"
}
