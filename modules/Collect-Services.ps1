param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "SystemInfo"
$CsvOut = Join-Path -Path $OutDir -ChildPath "Services.csv"

Write-Log -Level "INFO" -Message "Collecting Services Information..."

try {
    $WmiServices = Get-WmiObject Win32_Service
    $ServiceList = @()

    foreach ($Svc in $WmiServices) {
        $Path = $Svc.PathName
        
        # Parse binary path
        $BinPath = $Path
        if ($Path -match '"([^"]+)"') {
            $BinPath = $matches[1]
        } elseif ($Path -match '^[A-Za-z]:\\[^ ]+') {
            $BinPath = $matches[0]
        }
        
        # Check signature if file exists
        $IsSigned = $false
        if ($BinPath -and (Test-Path $BinPath)) {
            try {
                $Sig = Get-AuthenticodeSignature -FilePath $BinPath -ErrorAction SilentlyContinue
                if ($Sig.Status -eq 'Valid') { $IsSigned = $true }
            } catch {}
        }

        $ServiceList += [PSCustomObject]@{
            Name = $Svc.Name
            DisplayName = $Svc.DisplayName
            State = $Svc.State
            StartMode = $Svc.StartMode
            StartName = $Svc.StartName
            PathName = $Svc.PathName
            BinaryPath = $BinPath
            IsSigned = $IsSigned
        }
    }

    $ServiceList | Export-Csv -Path $CsvOut -NoTypeInformation

} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Services: $_"
}
