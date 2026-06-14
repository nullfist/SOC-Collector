param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Misc"
$CsvOut = Join-Path -Path $OutDir -ChildPath "RDP-Sessions.csv"

Write-Log -Level "INFO" -Message "Collecting RDP Information..."

try {
    $TxtOut = Join-Path -Path $OutDir -ChildPath "quser.txt"
    quser > $TxtOut 2>&1
    
    if (Get-Command Get-RDUserSession -ErrorAction SilentlyContinue) {
        Get-RDUserSession | Export-Csv -Path $CsvOut -NoTypeInformation
    }
} catch {
    Write-Log -Level "ERROR" -Message "Error collecting RDP Info: $_"
}
