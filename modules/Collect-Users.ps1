param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "SystemInfo"
$CsvOut = Join-Path -Path $OutDir -ChildPath "LocalUsers.csv"

Write-Log -Level "INFO" -Message "Collecting Local Users..."

try {
    $Users = Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True"
    $UserList = @()

    foreach ($User in $Users) {
        $UserList += [PSCustomObject]@{
            Name = $User.Name
            FullName = $User.FullName
            Disabled = $User.Disabled
            Lockout = $User.Lockout
            PasswordChangeable = $User.PasswordChangeable
            PasswordExpires = $User.PasswordExpires
            PasswordRequired = $User.PasswordRequired
            SID = $User.SID
        }
    }

    $UserList | Export-Csv -Path $CsvOut -NoTypeInformation

    # Local Administrators
    $AdminsCsv = Join-Path -Path $OutDir -ChildPath "LocalAdmins.csv"
    $AdminsGroup = Get-WmiObject Win32_Group -Filter "LocalAccount=True and Name='Administrators'"
    if ($AdminsGroup) {
        $Query = "GroupComponent=`"Win32_Group.Domain='$($AdminsGroup.Domain)',Name='Administrators'`""
        $Members = Get-WmiObject Win32_GroupUser -Filter $Query | Select-Object PartComponent
        $MembersList = @()
        foreach ($Mem in $Members) {
            if ($Mem.PartComponent -match 'Name="([^"]+)"') {
                $MembersList += [PSCustomObject]@{ Member = $matches[1] }
            }
        }
        $MembersList | Export-Csv -Path $AdminsCsv -NoTypeInformation
    }

} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Users: $_"
}
