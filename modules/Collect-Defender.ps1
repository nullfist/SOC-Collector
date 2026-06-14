param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "SystemInfo"
$CsvOut = Join-Path -Path $OutDir -ChildPath "DefenderStatus.csv"
$ThreatCsv = Join-Path -Path $OutDir -ChildPath "DefenderThreats.csv"

Write-Log -Level "INFO" -Message "Collecting Windows Defender Information..."

try {
    if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
        Get-MpComputerStatus | Select-Object AMEngineVersion, AMProductVersion, AntispywareSignatureVersion, AntivirusSignatureVersion, DefenderSignaturesOutOfDate, IsVirtualMachine, QuickScanAge, FullScanAge, RealTimeProtectionEnabled | Export-Csv -Path $CsvOut -NoTypeInformation
    }

    if (Get-Command Get-MpPreference -ErrorAction SilentlyContinue) {
        $Prefs = Get-MpPreference
        $PrefsObj = [PSCustomObject]@{
            ExclusionPath = ($Prefs.ExclusionPath -join ", ")
            ExclusionExtension = ($Prefs.ExclusionExtension -join ", ")
            ExclusionProcess = ($Prefs.ExclusionProcess -join ", ")
            DisableRealtimeMonitoring = $Prefs.DisableRealtimeMonitoring
            DisableIOAVProtection = $Prefs.DisableIOAVProtection
            DisableBehaviorMonitoring = $Prefs.DisableBehaviorMonitoring
        }
        $PrefsObj | Export-Csv -Path (Join-Path $OutDir "DefenderPreferences.csv") -NoTypeInformation
    }

    if (Get-Command Get-MpThreat -ErrorAction SilentlyContinue) {
        Get-MpThreat -ErrorAction SilentlyContinue | Export-Csv -Path $ThreatCsv -NoTypeInformation
    }
} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Defender Information: $_"
}
