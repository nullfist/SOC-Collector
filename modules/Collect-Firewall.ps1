param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Network"
$RulesCsv = Join-Path -Path $OutDir -ChildPath "FirewallRules.csv"
$ProfilesCsv = Join-Path -Path $OutDir -ChildPath "FirewallProfiles.csv"

Write-Log -Level "INFO" -Message "Collecting Firewall Information..."

try {
    if (Get-Command Get-NetFirewallRule -ErrorAction SilentlyContinue) {
        # Active firewall rules only
        Get-NetFirewallRule | Where-Object { $_.Enabled -eq "True" } | Export-Csv -Path $RulesCsv -NoTypeInformation
        Get-NetFirewallProfile | Export-Csv -Path $ProfilesCsv -NoTypeInformation
    } else {
        $TxtOut = Join-Path -Path $OutDir -ChildPath "Firewall.txt"
        netsh advfirewall show allprofiles > $TxtOut
        netsh advfirewall firewall show rule name=all >> $TxtOut
    }
} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Firewall: $_"
}
