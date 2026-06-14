param (
    [string]$CaseOutputDir,
    [object]$Config
)

Write-Log -Level "INFO" -Message "Calculating Hashes for Collected Evidence..."

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Misc"
$HashFile = Join-Path -Path $OutDir -ChildPath "EvidenceHashes.csv"

try {
    $Files = Get-ChildItem -Path $CaseOutputDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "EvidenceHashes.csv" }
    $HashList = @()
    
    foreach ($File in $Files) {
        $Hash = Get-FileHash -Path $File.FullName -Algorithm SHA256 -ErrorAction SilentlyContinue
        if ($Hash) {
            $RelativePath = $File.FullName.Replace($CaseOutputDir, "").TrimStart("\")
            $HashList += [PSCustomObject]@{
                Path = $RelativePath
                SHA256 = $Hash.Hash
                FileSize = $File.Length
            }
        }
    }

    $HashList | Export-Csv -Path $HashFile -NoTypeInformation

} catch {
    Write-Log -Level "ERROR" -Message "Error calculating hashes: $_"
}
