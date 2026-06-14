param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Processes"
$CsvOut = Join-Path -Path $OutDir -ChildPath "Processes.csv"
$JsonOut = Join-Path -Path $OutDir -ChildPath "Processes.json"

Write-Log -Level "INFO" -Message "Collecting Process Information..."

try {
    $WmiProcs = Get-WmiObject Win32_Process
    $ProcList = @()

    foreach ($WmiProc in $WmiProcs) {
        $Path = $WmiProc.ExecutablePath
        $CommandLine = $WmiProc.CommandLine
        
        # Determine User
        $User = "Unknown"
        try {
            $Owner = $WmiProc.GetOwner()
            if ($Owner.User) {
                $User = "$($Owner.Domain)\$($Owner.User)"
            }
        } catch {}

        # Check Signature if path exists
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

        # Flagging Logic
        $Flags = @()
        if (-not $IsSigned -and $Path) { $Flags += "Unsigned" }
        if ($Path -match "\\Temp\\" -or $Path -match "\\AppData\\") { $Flags += "SuspiciousPath" }
        
        # Very basic parent/child checking
        $ParentName = "Unknown"
        if ($WmiProc.ParentProcessId) {
            $Parent = $WmiProcs | Where-Object { $_.ProcessId -eq $WmiProc.ParentProcessId }
            if ($Parent) {
                $ParentName = $Parent.Name
                if (($WmiProc.Name -eq "cmd.exe" -or $WmiProc.Name -eq "powershell.exe") -and 
                    ($ParentName -match "winword.exe|excel.exe|powerpnt.exe|chrome.exe|iexplore.exe")) {
                    $Flags += "SuspiciousParentChild"
                }
            }
        }

        $FlagsStr = $Flags -join "|"

        $ProcObj = [PSCustomObject]@{
            PID = $WmiProc.ProcessId
            Name = $WmiProc.Name
            ParentPID = $WmiProc.ParentProcessId
            ParentName = $ParentName
            Path = $Path
            CommandLine = $CommandLine
            User = $User
            StartTime = $WmiProc.ConvertToDateTime($WmiProc.CreationDate)
            MemoryUsageMB = [math]::Round($WmiProc.WorkingSetSize / 1MB, 2)
            IsSigned = $IsSigned
            Signer = $Signer
            Flags = $FlagsStr
        }
        $ProcList += $ProcObj
    }

    # Export to CSV and JSON
    $ProcList | Export-Csv -Path $CsvOut -NoTypeInformation
    $ProcList | ConvertTo-Json -Depth 3 | Out-File -FilePath $JsonOut

} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Processes: $_"
}
