param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "SystemInfo"
$CsvOut = Join-Path -Path $OutDir -ChildPath "Drivers.csv"

Write-Log -Level "INFO" -Message "Collecting Drivers Information..."

try {
    # Using driverquery.exe for base information, plus WMI for file paths
    $DriversWmi = Get-WmiObject Win32_SystemDriver
    $DriverList = @()

    foreach ($Drv in $DriversWmi) {
        $Path = $Drv.PathName
        
        # Check signature if file exists
        $IsSigned = $false
        $Signer = ""
        if ($Path -and (Test-Path $Path)) {
            try {
                $Sig = Get-AuthenticodeSignature -FilePath $Path -ErrorAction SilentlyContinue
                if ($Sig.Status -eq 'Valid') { 
                    $IsSigned = $true
                    $Signer = $Sig.SignerCertificate.Subject
                }
            } catch {}
        }

        # Flag anomalies
        $Flags = @()
        if (-not $IsSigned -and $Path) { $Flags += "Unsigned" }
        if ($Drv.ServiceType -match "Kernel" -and -not $IsSigned) { $Flags += "UnsignedKernelDriver" }
        
        $DriverList += [PSCustomObject]@{
            Name = $Drv.Name
            DisplayName = $Drv.DisplayName
            State = $Drv.State
            ServiceType = $Drv.ServiceType
            PathName = $Path
            IsSigned = $IsSigned
            Signer = $Signer
            Flags = ($Flags -join "|")
        }
    }

    $DriverList | Export-Csv -Path $CsvOut -NoTypeInformation

} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Drivers: $_"
}
