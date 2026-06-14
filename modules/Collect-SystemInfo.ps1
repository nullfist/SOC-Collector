param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "SystemInfo"
$TxtOut = Join-Path -Path $OutDir -ChildPath "systeminfo.txt"
$CsvOut = Join-Path -Path $OutDir -ChildPath "systeminfo.csv"
$PatchesCsv = Join-Path -Path $OutDir -ChildPath "installed_patches.csv"

# Gather systeminfo
Write-Log -Level "INFO" -Message "Collecting System Information..."

try {
    # Basic info
    $OS = Get-WmiObject Win32_OperatingSystem
    $CompSys = Get-WmiObject Win32_ComputerSystem
    $Bios = Get-WmiObject Win32_BIOS
    $CPU = Get-WmiObject Win32_Processor | Select-Object -First 1
    $TZ = Get-WmiObject Win32_TimeZone

    $LoggedOnUsers = (Get-WmiObject Win32_LoggedOnUser | Select-Object -ExpandProperty Antecedent | Out-String).Split("`n") | Select-String "Name="
    $UsersStr = ($LoggedOnUsers -replace ".*Name=`"([^`"]+)`".*",'$1') -join ", "

    $Uptime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
    
    # RAM in GB
    $TotalRAM = [math]::Round($CompSys.TotalPhysicalMemory / 1GB, 2)

    # Drives
    $Drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | ForEach-Object { "$($_.DeviceID) ($([math]::Round($_.FreeSpace / 1GB, 2))GB free of $([math]::Round($_.Size / 1GB, 2))GB)" }
    $DrivesStr = $Drives -join "; "

    $SysInfoObj = [PSCustomObject]@{
        Hostname       = $CompSys.Name
        Domain         = $CompSys.Domain
        LoggedOnUsers  = $UsersStr
        OSName         = $OS.Caption
        OSVersion      = $OS.Version
        BuildNumber    = $OS.BuildNumber
        BIOSVersion    = $Bios.SMBIOSBIOSVersion
        Manufacturer   = $CompSys.Manufacturer
        Model          = $CompSys.Model
        UptimeDays     = $Uptime.Days
        UptimeHours    = $Uptime.Hours
        Timezone       = $TZ.Caption
        CPU            = $CPU.Name
        RAM_GB         = $TotalRAM
        LocalDrives    = $DrivesStr
    }

    # Export to CSV
    $SysInfoObj | Export-Csv -Path $CsvOut -NoTypeInformation

    # Export to TXT
    $SysInfoObj | Out-String | Out-File -FilePath $TxtOut

    # Installed Patches
    Write-Log -Level "INFO" -Message "Collecting Installed Patches..."
    $Patches = Get-HotFix | Select-Object HotFixID, Description, InstalledOn, InstalledBy
    $Patches | Export-Csv -Path $PatchesCsv -NoTypeInformation

} catch {
    Write-Log -Level "ERROR" -Message "Error collecting SystemInfo: $_"
}
