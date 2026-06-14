param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "SystemInfo"
$CsvOut = Join-Path -Path $OutDir -ChildPath "BitLocker.csv"

Write-Log -Level "INFO" -Message "Collecting BitLocker Information..."

try {
    # Check if BitLocker module exists, else use WMI/manage-bde
    $BLVolumes = @()
    if (Get-Command "Get-BitLockerVolume" -ErrorAction SilentlyContinue) {
        $Vols = Get-BitLockerVolume
        foreach ($Vol in $Vols) {
            $BLVolumes += [PSCustomObject]@{
                MountPoint = $Vol.MountPoint
                VolumeType = $Vol.VolumeType
                ProtectionStatus = $Vol.ProtectionStatus
                EncryptionPercentage = $Vol.EncryptionPercentage
                VolumeStatus = $Vol.VolumeStatus
            }
        }
    } else {
        # Fallback to manage-bde output
        $ManageBdeOutput = manage-bde -status
        $BLVolumes += [PSCustomObject]@{
            RawOutput = ($ManageBdeOutput -join "`n")
        }
    }

    if ($BLVolumes) {
        $BLVolumes | Export-Csv -Path $CsvOut -NoTypeInformation
    }

} catch {
    Write-Log -Level "ERROR" -Message "Error collecting BitLocker status: $_"
}
