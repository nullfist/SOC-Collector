param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Misc"
$CsvOut = Join-Path -Path $OutDir -ChildPath "USBHistory.csv"

Write-Log -Level "INFO" -Message "Collecting USB History..."

try {
    $USBList = @()
    
    # USBSTOR
    $USBSTORKey = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
    if (Test-Path $USBSTORKey) {
        $Devices = Get-ChildItem -Path $USBSTORKey -ErrorAction SilentlyContinue
        foreach ($Dev in $Devices) {
            $Instances = Get-ChildItem -Path $Dev.PSPath -ErrorAction SilentlyContinue
            foreach ($Inst in $Instances) {
                $Props = Get-ItemProperty -Path $Inst.PSPath -ErrorAction SilentlyContinue
                $FriendlyName = $Props.FriendlyName
                $HardwareID = $Props.HardwareID -join ","
                
                $USBList += [PSCustomObject]@{
                    Category = "USBSTOR"
                    DeviceID = $Dev.PSChildName
                    InstanceID = $Inst.PSChildName
                    FriendlyName = $FriendlyName
                    HardwareID = $HardwareID
                }
            }
        }
    }

    # MountedDevices
    $MountedKey = "HKLM:\SYSTEM\MountedDevices"
    if (Test-Path $MountedKey) {
        $Items = Get-ItemProperty -Path $MountedKey -ErrorAction SilentlyContinue
        foreach ($Prop in $Items.psobject.properties) {
            if ($Prop.Name -notmatch '^(PSPath|PSParentPath|PSChildName|PSDrive|PSProvider)$') {
                # Attempt to decode byte array if present
                $ValStr = ""
                if ($Prop.Value -is [byte[]]) {
                    # basic ascii decode
                    $ValStr = [System.Text.Encoding]::ASCII.GetString($Prop.Value) -replace '[^\x20-\x7E]', ''
                } else {
                    $ValStr = $Prop.Value
                }
                
                $USBList += [PSCustomObject]@{
                    Category = "MountedDevices"
                    DeviceID = $Prop.Name
                    InstanceID = ""
                    FriendlyName = ""
                    HardwareID = $ValStr
                }
            }
        }
    }

    $USBList | Export-Csv -Path $CsvOut -NoTypeInformation

} catch {
    Write-Log -Level "ERROR" -Message "Error collecting USB History: $_"
}
