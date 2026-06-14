param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Network"
$CsvOut = Join-Path -Path $OutDir -ChildPath "DNSCache.csv"

Write-Log -Level "INFO" -Message "Collecting DNS Cache..."

try {
    if (Get-Command Get-DnsClientCache -ErrorAction SilentlyContinue) {
        $Cache = Get-DnsClientCache
        $Cache | Export-Csv -Path $CsvOut -NoTypeInformation
    } else {
        $TxtOut = Join-Path -Path $OutDir -ChildPath "DNSCache.txt"
        ipconfig /displaydns > $TxtOut
    }
} catch {
    Write-Log -Level "ERROR" -Message "Error collecting DNS Cache: $_"
}
