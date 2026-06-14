param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Misc"

Write-Log -Level "INFO" -Message "Collecting SMB Information..."

try {
    if (Get-Command Get-SmbSession -ErrorAction SilentlyContinue) {
        Get-SmbSession | Export-Csv -Path (Join-Path $OutDir "SmbSessions.csv") -NoTypeInformation
        Get-SmbConnection | Export-Csv -Path (Join-Path $OutDir "SmbConnections.csv") -NoTypeInformation
        Get-SmbServerConfiguration | Export-Csv -Path (Join-Path $OutDir "SmbServerConfig.csv") -NoTypeInformation
        Get-SmbClientConfiguration | Export-Csv -Path (Join-Path $OutDir "SmbClientConfig.csv") -NoTypeInformation
    }
} catch {
    Write-Log -Level "ERROR" -Message "Error collecting SMB: $_"
}
