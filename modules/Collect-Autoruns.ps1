param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Persistence"
$CsvOut = Join-Path -Path $OutDir -ChildPath "Autoruns.csv"

Write-Log -Level "INFO" -Message "Collecting Autoruns (Custom PS Implementation)..."

try {
    $AutorunList = @()

    # Startup Folders
    $AllUsersStartup = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    $UserStartups = Get-ChildItem "C:\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -ErrorAction SilentlyContinue

    $StartupFiles = @()
    if (Test-Path $AllUsersStartup) { $StartupFiles += Get-ChildItem $AllUsersStartup -File }
    $StartupFiles += $UserStartups

    foreach ($File in $StartupFiles) {
        # Check Signature
        $IsSigned = $false
        try {
            $Sig = Get-AuthenticodeSignature -FilePath $File.FullName -ErrorAction SilentlyContinue
            if ($Sig.Status -eq 'Valid') { $IsSigned = $true }
        } catch {}

        $AutorunList += [PSCustomObject]@{
            Category = "Startup Folder"
            Name = $File.Name
            Location = $File.FullName
            IsSigned = $IsSigned
        }
    }

    # IFEO
    $IFEOKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
    if (Test-Path $IFEOKey) {
        $Keys = Get-ChildItem -Path $IFEOKey -ErrorAction SilentlyContinue
        foreach ($K in $Keys) {
            $Debugger = (Get-ItemProperty -Path $K.PSPath -Name "Debugger" -ErrorAction SilentlyContinue).Debugger
            if ($Debugger) {
                $AutorunList += [PSCustomObject]@{
                    Category = "IFEO"
                    Name = $K.PSChildName
                    Location = $K.PSPath
                    IsSigned = "N/A"
                    Details = "Debugger: $Debugger"
                }
            }
        }
    }

    $AutorunList | Export-Csv -Path $CsvOut -NoTypeInformation

} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Autoruns: $_"
}
