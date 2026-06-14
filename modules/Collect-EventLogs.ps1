param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "EventLogs"

$LogNames = @{
    "Security" = "Security"
    "System" = "System"
    "Application" = "Application"
    "PowerShell-Operational" = "Microsoft-Windows-PowerShell/Operational"
    "Windows-Defender" = "Microsoft-Windows-Windows Defender/Operational"
    "Sysmon" = "Microsoft-Windows-Sysmon/Operational"
    "TerminalServices-LocalSessionManager" = "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"
    "TerminalServices-RemoteConnectionManager" = "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational"
    "TaskScheduler" = "Microsoft-Windows-TaskScheduler/Operational"
    "DNS-Client" = "Microsoft-Windows-DNS-Client/Operational"
    "WMI-Activity" = "Microsoft-Windows-WMI-Activity/Operational"
}

# Optional Sysmon download
if ($Config.Settings.InstallSysmonIfMissing) {
    try {
        $SysmonExists = Get-WinEvent -ListLog "Microsoft-Windows-Sysmon/Operational" -ErrorAction SilentlyContinue
        if (-not $SysmonExists) {
            Write-Log -Level "WARN" -Message "Sysmon not found. Attempting to download and install Sysmon (Default Config)..."
            $SysmonUrl = "https://live.sysinternals.com/Sysmon64.exe"
            $SysmonPath = Join-Path $env:TEMP "Sysmon64.exe"
            Invoke-WebRequest -Uri $SysmonUrl -OutFile $SysmonPath -UseBasicParsing
            
            # Install sysmon with default config
            Start-Process -FilePath $SysmonPath -ArgumentList "-accepteula -i" -Wait -WindowStyle Hidden
            Start-Sleep -Seconds 3 # wait for it to start logging
            Write-Log -Level "INFO" -Message "Sysmon installed successfully."
        }
    } catch {
        Write-Log -Level "ERROR" -Message "Failed to install Sysmon: $_"
    }
}

foreach ($Key in $LogNames.Keys) {
    $LogName = $LogNames[$Key]
    $EvtxOut = Join-Path -Path $OutDir -ChildPath "$Key.evtx"
    $CsvOut = Join-Path -Path $OutDir -ChildPath "$Key-Summary.csv"

    Write-Log -Level "INFO" -Message "Collecting Event Log: $LogName"
    
    try {
        # Check if log exists
        $LogExists = Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue
        if ($LogExists) {
            # Export raw EVTX using wevtutil
            $wevtutil = "$env:windir\System32\wevtutil.exe"
            & $wevtutil epl $LogName $EvtxOut

            # Create a summary of the last 1000 events
            $Events = Get-WinEvent -LogName $LogName -MaxEvents 1000 -ErrorAction SilentlyContinue
            if ($Events) {
                $Events | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message | 
                          Export-Csv -Path $CsvOut -NoTypeInformation -Encoding UTF8
            }
        } else {
            Write-Log -Level "WARN" -Message "Event Log not found or empty: $LogName"
        }
    } catch {
        Write-Log -Level "ERROR" -Message "Error collecting $LogName: $_"
    }
}
