param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Misc"

Write-Log -Level "INFO" -Message "Collecting Shares Information..."

try {
    if (Get-Command Get-SmbShare -ErrorAction SilentlyContinue) {
        Get-SmbShare | Export-Csv -Path (Join-Path $OutDir "Shares.csv") -NoTypeInformation
    } else {
        Get-WmiObject Win32_Share | Export-Csv -Path (Join-Path $OutDir "Shares_WMI.csv") -NoTypeInformation
    }
} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Shares: $_"
}
