param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Network"

Write-Log -Level "INFO" -Message "Collecting Network Information..."

try {
    # netstat -ano
    $NetstatOut = Join-Path -Path $OutDir -ChildPath "netstat.txt"
    netstat -ano > $NetstatOut

    # Get-NetTCPConnection
    $TcpOut = Join-Path -Path $OutDir -ChildPath "NetTCPConnection.csv"
    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        $TcpConns = Get-NetTCPConnection -ErrorAction SilentlyContinue
        # Resolve Hostnames where possible
        $ResolvedTcp = @()
        foreach ($Conn in $TcpConns) {
            $RemoteHost = ""
            if ($Conn.RemoteAddress -and $Conn.RemoteAddress -notmatch "^0\.0\.0\.0$" -and $Conn.RemoteAddress -notmatch "^127\.") {
                try {
                    $RemoteHost = [System.Net.Dns]::GetHostEntry($Conn.RemoteAddress).HostName
                } catch {}
            }
            $ResolvedTcp += [PSCustomObject]@{
                LocalAddress = $Conn.LocalAddress
                LocalPort = $Conn.LocalPort
                RemoteAddress = $Conn.RemoteAddress
                RemotePort = $Conn.RemotePort
                RemoteHost = $RemoteHost
                State = $Conn.State
                AppliedSetting = $Conn.AppliedSetting
                OwningProcess = $Conn.OwningProcess
            }
        }
        $ResolvedTcp | Export-Csv -Path $TcpOut -NoTypeInformation
    }

    # Get-NetUDPEndpoint
    $UdpOut = Join-Path -Path $OutDir -ChildPath "NetUDPEndpoint.csv"
    if (Get-Command Get-NetUDPEndpoint -ErrorAction SilentlyContinue) {
        Get-NetUDPEndpoint -ErrorAction SilentlyContinue | Export-Csv -Path $UdpOut -NoTypeInformation
    }

    # arp -a
    $ArpOut = Join-Path -Path $OutDir -ChildPath "arp.txt"
    arp -a > $ArpOut

    # ipconfig /all
    $IpconfigOut = Join-Path -Path $OutDir -ChildPath "ipconfig.txt"
    ipconfig /all > $IpconfigOut

    # route print
    $RouteOut = Join-Path -Path $OutDir -ChildPath "route_print.txt"
    route print > $RouteOut

} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Network Info: $_"
}
