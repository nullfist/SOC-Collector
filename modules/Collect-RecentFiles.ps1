param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Misc"
$CsvOut = Join-Path -Path $OutDir -ChildPath "RecentFiles.csv"

Write-Log -Level "INFO" -Message "Collecting Recent Files Information..."

try {
    $Users = Get-ChildItem -Path "C:\Users" -Directory
    $RecentList = @()

    foreach ($User in $Users) {
        $RecentPath = Join-Path $User.FullName "AppData\Roaming\Microsoft\Windows\Recent"
        if (Test-Path $RecentPath) {
            $Files = Get-ChildItem -Path $RecentPath -Filter "*.lnk" -ErrorAction SilentlyContinue
            foreach ($File in $Files) {
                # Attempt to resolve LNK target (requires WScript.Shell, works in PS 5.1 natively usually)
                $Target = ""
                try {
                    $WshShell = New-Object -ComObject WScript.Shell
                    $Shortcut = $WshShell.CreateShortcut($File.FullName)
                    $Target = $Shortcut.TargetPath
                } catch {}

                $RecentList += [PSCustomObject]@{
                    User = $User.Name
                    LnkName = $File.Name
                    Target = $Target
                    LnkCreationTime = $File.CreationTime
                    LnkLastWriteTime = $File.LastWriteTime
                }
            }
        }
    }

    if ($RecentList) {
        $RecentList | Export-Csv -Path $CsvOut -NoTypeInformation
    }
} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Recent Files: $_"
}
