param (
    [string]$CaseOutputDir,
    [string]$CaseID
)

Write-Log -Level "INFO" -Message "Generating HTML Executive Report..."

$ReportDir = Join-Path -Path $CaseOutputDir -ChildPath "Reports"
$HtmlOut = Join-Path -Path $ReportDir -ChildPath "$CaseID-ExecutiveReport.html"

try {
    # HTML Skeleton with Inline CSS
    $Html = @"
<!DOCTYPE html>
<html>
<head>
    <title>SOC Triage Report: $CaseID</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f5f7; color: #333; margin: 0; padding: 20px; }
        .container { max-width: 1000px; margin: 0 auto; background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        h2 { color: #2980b9; margin-top: 30px; border-bottom: 1px solid #eee; padding-bottom: 5px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background-color: #f8f9fa; font-weight: bold; }
        .badge { padding: 4px 8px; border-radius: 4px; font-weight: bold; color: white; display: inline-block; font-size: 0.9em; }
        .critical { background-color: #e74c3c; }
        .high { background-color: #e67e22; }
        .medium { background-color: #f1c40f; color: #333; }
        .low { background-color: #3498db; }
        .info { background-color: #95a5a6; }
        .section-box { padding: 15px; margin-bottom: 20px; border-radius: 5px; border-left: 5px solid #3498db; background-color: #f9f9f9; }
    </style>
</head>
<body>
    <div class="container">
        <h1>SOC Triage Executive Report</h1>
        <div class="section-box">
            <p><strong>Case ID:</strong> $CaseID</p>
            <p><strong>Date Generated:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
            <p><strong>Hostname:</strong> $($env:COMPUTERNAME)</p>
        </div>

        <h2>Host Summary</h2>
        <p>Refer to the `SystemInfo\systeminfo.csv` file for full details on the operating system, processor, memory, and uptime.</p>
        
        <h2>Suspicious Findings</h2>
        <p>This section flags high-level anomalies found during collection.</p>
        <table>
            <tr><th>Severity</th><th>Category</th><th>Details</th></tr>
"@

    # Basic Analysis to populate report
    $SuspiciousFindings = @()

    # 1. Defender Status
    $DefPrefsCsv = Join-Path -Path $CaseOutputDir -ChildPath "SystemInfo\DefenderPreferences.csv"
    if (Test-Path $DefPrefsCsv) {
        $Def = Import-Csv $DefPrefsCsv
        if ($Def.DisableRealtimeMonitoring -eq 'True') {
            $SuspiciousFindings += "<tr><td><span class='badge critical'>Critical</span></td><td>Defender</td><td>Real-time monitoring is DISABLED.</td></tr>"
        }
        if ($Def.ExclusionPath -or $Def.ExclusionExtension -or $Def.ExclusionProcess) {
            $SuspiciousFindings += "<tr><td><span class='badge medium'>Medium</span></td><td>Defender Exclusions</td><td>Exclusions exist: Paths ($($Def.ExclusionPath)), Exts ($($Def.ExclusionExtension)), Procs ($($Def.ExclusionProcess))</td></tr>"
        }
    }

    # 2. Unsigned Drivers
    $DriversCsv = Join-Path -Path $CaseOutputDir -ChildPath "SystemInfo\Drivers.csv"
    if (Test-Path $DriversCsv) {
        $UnsignedKernels = Import-Csv $DriversCsv | Where-Object { $_.Flags -match "UnsignedKernelDriver" }
        if ($UnsignedKernels) {
            $SuspiciousFindings += "<tr><td><span class='badge high'>High</span></td><td>Drivers</td><td>Found $($UnsignedKernels.Count) unsigned kernel drivers.</td></tr>"
        }
    }

    # 3. Processes
    $ProcCsv = Join-Path -Path $CaseOutputDir -ChildPath "Processes\Processes.csv"
    if (Test-Path $ProcCsv) {
        $Procs = Import-Csv $ProcCsv
        $SuspiciousPath = $Procs | Where-Object { $_.Flags -match "SuspiciousPath" }
        if ($SuspiciousPath) {
            $SuspiciousFindings += "<tr><td><span class='badge high'>High</span></td><td>Processes</td><td>Found $($SuspiciousPath.Count) processes running from Temp/AppData.</td></tr>"
        }
        $SuspiciousParent = $Procs | Where-Object { $_.Flags -match "SuspiciousParentChild" }
        if ($SuspiciousParent) {
            $SuspiciousFindings += "<tr><td><span class='badge critical'>Critical</span></td><td>Processes</td><td>Found $($SuspiciousParent.Count) suspicious parent-child relationships (e.g. Office spawning cmd).</td></tr>"
        }
    }

    if ($SuspiciousFindings.Count -eq 0) {
        $Html += "<tr><td colspan='3'>No immediate high-level anomalies flagged automatically. Manual analysis required.</td></tr>"
    } else {
        $Html += ($SuspiciousFindings -join "`n")
    }

    $Html += @"
        </table>

        <h2>Summary of Collected Artifacts</h2>
        <ul>
            <li><strong>Event Logs:</strong> Collected key EVTX files and summary CSVs.</li>
            <li><strong>Persistence:</strong> Collected Run keys, Scheduled Tasks, Autoruns, and WMI consumers.</li>
            <li><strong>Network:</strong> Collected connections, DNS cache, and firewall configuration.</li>
            <li><strong>Files:</strong> Hashed collected evidence to ensure chain of custody.</li>
        </ul>

        <h2>Recommendations</h2>
        <div class="section-box">
            <ul>
                <li>Review the `EventLogs` folder for anomalous log entries (e.g., clearing of event logs, suspicious process executions).</li>
                <li>Analyze `Processes\Processes.csv` for unauthorized execution patterns.</li>
                <li>Examine `Persistence` folder to identify backdoors.</li>
            </ul>
        </div>
    </div>
</body>
</html>
"@

    $Html | Out-File -FilePath $HtmlOut -Encoding UTF8
    Write-Log -Level "STATUS" -Message "Report generated at $HtmlOut"

} catch {
    Write-Log -Level "ERROR" -Message "Error generating report: $_"
}
