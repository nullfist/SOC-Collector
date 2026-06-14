<#
.SYNOPSIS
    SOC-Triage-Collector Master Script
.DESCRIPTION
    This script initializes the environment, creates necessary output folders,
    reads the configuration, and executes individual collection modules.
#>

param (
    [string]$AnalystName = $env:USERNAME,
    [string]$ConfigPath = ".\config\collector-config.json"
)

$ErrorActionPreference = "Continue"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Hostname = $env:COMPUTERNAME
$CaseID = "CASE-$Hostname-$Timestamp"

# ==========================================
# 1. Verification Checks
# ==========================================

Write-Host "[*] Initializing SOC-Triage-Collector..." -ForegroundColor Cyan

# Check Admin Privileges
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Host "[!] ERROR: Please run this script as an Administrator." -ForegroundColor Red
    Exit
}

# Check PowerShell Version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[!] ERROR: PowerShell 5.1 or higher is required." -ForegroundColor Red
    Exit
}

# Check Disk Space (Require at least 2GB free on system drive)
$Drive = Get-PSDrive -Name $env:SystemDrive.Substring(0,1)
if (($Drive.Free / 1GB) -lt 2) {
    Write-Host "[!] WARNING: Less than 2GB of free disk space available. Collection might fail." -ForegroundColor Yellow
}

# ==========================================
# 2. Setup Directories
# ==========================================

# Read Config
if (-not (Test-Path $ConfigPath)) {
    Write-Host "[!] ERROR: Configuration file not found at $ConfigPath" -ForegroundColor Red
    Exit
}

$Config = Get-Content $ConfigPath | ConvertFrom-Json
$BaseOutputDir = $Config.Settings.OutputDirectory
$BaseLogDir = $Config.Settings.LogDirectory

$CaseOutputDir = Join-Path -Path $BaseOutputDir -ChildPath $CaseID
$CaseLogFile = Join-Path -Path $BaseLogDir -ChildPath "collector-$CaseID.log"

# Define Output Subdirectories
$OutDirs = @(
    "SystemInfo",
    "EventLogs",
    "Processes",
    "Persistence",
    "Network",
    "Browser",
    "Reports",
    "Misc"
)

# Create Directories
New-Item -ItemType Directory -Force -Path $BaseLogDir | Out-Null
New-Item -ItemType Directory -Force -Path $CaseOutputDir | Out-Null
foreach ($Dir in $OutDirs) {
    New-Item -ItemType Directory -Force -Path (Join-Path -Path $CaseOutputDir -ChildPath $Dir) | Out-Null
}

# ==========================================
# 3. Logging Setup
# ==========================================

function Write-Log {
    param([string]$Message, [string]$Level="INFO")
    $LogTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMsg = "[$LogTime] [$Level] $Message"
    Add-Content -Path $CaseLogFile -Value $LogMsg
    
    switch ($Level) {
        "INFO"    { Write-Host $LogMsg -ForegroundColor Green }
        "WARN"    { Write-Host $LogMsg -ForegroundColor Yellow }
        "ERROR"   { Write-Host $LogMsg -ForegroundColor Red }
        "STATUS"  { Write-Host $LogMsg -ForegroundColor Cyan }
        Default   { Write-Host $LogMsg }
    }
}

Write-Log -Level "STATUS" -Message "Triage started for Hostname: $Hostname | CaseID: $CaseID | Analyst: $AnalystName"

# ==========================================
# 4. Execute Modules
# ==========================================

# We will dynamically find modules in the modules/ folder based on the config.
# For each property in $Config.Modules that is true, we look for a corresponding script.

$ModuleDir = ".\modules"
$ModulesToRun = $Config.Modules.psobject.properties | Where-Object { $_.Value -eq $true }

foreach ($Mod in $ModulesToRun) {
    # Expected module script name, e.g., CollectSystemInfo -> Collect-SystemInfo.ps1
    # We will use Regex to insert a dash between 'Collect' and the rest of the name
    $ScriptName = $Mod.Name -replace '^Collect', 'Collect-'
    if ($ScriptName -notmatch '-') { $ScriptName = $Mod.Name }
    
    $ScriptPath = Join-Path -Path $ModuleDir -ChildPath "$ScriptName.ps1"
    
    if (Test-Path $ScriptPath) {
        Write-Log -Level "INFO" -Message "Starting module: $ScriptName"
        $StartTime = Get-Date
        try {
            # Pass relevant variables to the module via script scope or arguments.
            # In this framework, we execute them in the current scope so they can use Write-Log and $CaseOutputDir
            . $ScriptPath -CaseOutputDir $CaseOutputDir -Config $Config
        }
        catch {
            Write-Log -Level "ERROR" -Message "Module $ScriptName failed: $_"
        }
        $EndTime = Get-Date
        $Duration = ($EndTime - $StartTime).TotalSeconds
        Write-Log -Level "INFO" -Message "Finished module: $ScriptName in $Duration seconds"
    } else {
        Write-Log -Level "WARN" -Message "Module script not found: $ScriptPath"
    }
}

# ==========================================
# 5. Reporting and Packaging
# ==========================================

if ($Config.Settings.GenerateHTMLReport) {
    Write-Log -Level "INFO" -Message "Generating HTML Report..."
    $ReportScript = Join-Path -Path $ModuleDir -ChildPath "Generate-Report.ps1"
    if (Test-Path $ReportScript) {
        try { . $ReportScript -CaseOutputDir $CaseOutputDir -CaseID $CaseID }
        catch { Write-Log -Level "ERROR" -Message "Generate-Report failed: $_" }
    }
}

if ($Config.Settings.CompressOutput) {
    Write-Log -Level "INFO" -Message "Compressing Evidence..."
    $CompressScript = Join-Path -Path $ModuleDir -ChildPath "Compress-Evidence.ps1"
    if (Test-Path $CompressScript) {
        try { . $CompressScript -CaseOutputDir $CaseOutputDir -CaseID $CaseID }
        catch { Write-Log -Level "ERROR" -Message "Compress-Evidence failed: $_" }
    }
}

Write-Log -Level "STATUS" -Message "Triage completed successfully. Evidence stored in $CaseOutputDir"
