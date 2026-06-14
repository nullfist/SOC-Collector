param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Persistence"
$CsvOut = Join-Path -Path $OutDir -ChildPath "Persistence.csv"

Write-Log -Level "INFO" -Message "Collecting Persistence Information..."

try {
    $PersistList = @()
    
    # Run keys
    $RunKeys = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    )
    
    foreach ($Key in $RunKeys) {
        if (Test-Path $Key) {
            $Items = Get-ItemProperty -Path $Key -ErrorAction SilentlyContinue
            foreach ($Prop in $Items.psobject.properties) {
                if ($Prop.Name -notmatch '^(PSPath|PSParentPath|PSChildName|PSDrive|PSProvider)$') {
                    $PersistList += [PSCustomObject]@{
                        Type = "RunKey"
                        Location = $Key
                        Name = $Prop.Name
                        Value = $Prop.Value
                    }
                }
            }
        }
    }

    # WMI Event Consumers
    try {
        $WmiConsumers = Get-WmiObject -Namespace root\subscription -Class __EventConsumer -ErrorAction SilentlyContinue
        foreach ($Consumer in $WmiConsumers) {
            $PersistList += [PSCustomObject]@{
                Type = "WMI_Consumer"
                Location = "root\subscription"
                Name = $Consumer.Name
                Value = $Consumer.CommandLineTemplate
            }
        }
    } catch {}

    # Winlogon
    $WinlogonKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    if (Test-Path $WinlogonKey) {
        $Items = Get-ItemProperty -Path $WinlogonKey -ErrorAction SilentlyContinue
        $PersistList += [PSCustomObject]@{ Type="Winlogon"; Location=$WinlogonKey; Name="Shell"; Value=$Items.Shell }
        $PersistList += [PSCustomObject]@{ Type="Winlogon"; Location=$WinlogonKey; Name="Userinit"; Value=$Items.Userinit }
    }

    $PersistList | Export-Csv -Path $CsvOut -NoTypeInformation

} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Persistence: $_"
}
