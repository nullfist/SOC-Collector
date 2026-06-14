param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Persistence"
$CsvOut = Join-Path -Path $OutDir -ChildPath "ScheduledTasks.csv"

Write-Log -Level "INFO" -Message "Collecting Scheduled Tasks..."

try {
    if (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue) {
        $Tasks = Get-ScheduledTask
        $TaskList = @()
        foreach ($Task in $Tasks) {
            $ActionPath = ""
            $ActionArgs = ""
            if ($Task.Actions) {
                $ActionPath = $Task.Actions[0].Execute
                $ActionArgs = $Task.Actions[0].Arguments
            }
            
            $TaskList += [PSCustomObject]@{
                TaskName = $Task.TaskName
                TaskPath = $Task.TaskPath
                State = $Task.State
                Author = $Task.Author
                Execute = $ActionPath
                Arguments = $ActionArgs
            }
        }
        $TaskList | Export-Csv -Path $CsvOut -NoTypeInformation
    } else {
        schtasks /query /fo CSV /v > $CsvOut
    }
} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Scheduled Tasks: $_"
}
