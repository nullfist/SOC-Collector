param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Misc"
$CsvOut = Join-Path -Path $OutDir -ChildPath "PrefetchFiles.csv"

Write-Log -Level "INFO" -Message "Collecting Prefetch Information..."

try {
    $PrefetchDir = "C:\Windows\Prefetch"
    if (Test-Path $PrefetchDir) {
        $Files = Get-ChildItem -Path $PrefetchDir -Filter "*.pf" -ErrorAction SilentlyContinue
        $List = @()
        foreach ($File in $Files) {
            $List += [PSCustomObject]@{
                FileName = $File.Name
                SizeKB = [math]::Round($File.Length / 1KB, 2)
                CreationTime = $File.CreationTime
                LastWriteTime = $File.LastWriteTime
                LastAccessTime = $File.LastAccessTime
            }
        }
        $List | Export-Csv -Path $CsvOut -NoTypeInformation

        # Copy actual .pf files
        $PfOutDir = Join-Path $OutDir "PrefetchFiles"
        New-Item -ItemType Directory -Force -Path $PfOutDir | Out-Null
        Copy-Item -Path "$PrefetchDir\*.pf" -Destination $PfOutDir -ErrorAction SilentlyContinue
    }
} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Prefetch: $_"
}
