param (
    [string]$CaseOutputDir,
    [object]$Config
)

$OutDir = Join-Path -Path $CaseOutputDir -ChildPath "Browser"
Write-Log -Level "INFO" -Message "Collecting Browser Artifacts (Metadata only)..."

try {
    $Users = Get-ChildItem -Path "C:\Users" -Directory
    
    foreach ($User in $Users) {
        $UserName = $User.Name
        
        # Chrome
        $ChromePath = Join-Path $User.FullName "AppData\Local\Google\Chrome\User Data"
        if (Test-Path $ChromePath) {
            $Dest = Join-Path $OutDir "Chrome_$UserName"
            New-Item -ItemType Directory -Force -Path $Dest | Out-Null
            
            # Default Profile
            $Files = @("History", "Cookies", "Web Data", "Login Data", "Bookmarks")
            foreach ($F in $Files) {
                $Src = Join-Path $ChromePath "Default\$F"
                if (Test-Path $Src) { Copy-Item $Src -Destination $Dest -ErrorAction SilentlyContinue }
            }
        }

        # Edge
        $EdgePath = Join-Path $User.FullName "AppData\Local\Microsoft\Edge\User Data"
        if (Test-Path $EdgePath) {
            $Dest = Join-Path $OutDir "Edge_$UserName"
            New-Item -ItemType Directory -Force -Path $Dest | Out-Null
            
            $Files = @("History", "Cookies", "Web Data", "Login Data", "Bookmarks")
            foreach ($F in $Files) {
                $Src = Join-Path $EdgePath "Default\$F"
                if (Test-Path $Src) { Copy-Item $Src -Destination $Dest -ErrorAction SilentlyContinue }
            }
        }

        # Firefox
        $FFPath = Join-Path $User.FullName "AppData\Roaming\Mozilla\Firefox\Profiles"
        if (Test-Path $FFPath) {
            $Dest = Join-Path $OutDir "Firefox_$UserName"
            New-Item -ItemType Directory -Force -Path $Dest | Out-Null
            
            $Profiles = Get-ChildItem $FFPath -Directory
            foreach ($Prof in $Profiles) {
                $Files = @("places.sqlite", "cookies.sqlite", "downloads.sqlite")
                foreach ($F in $Files) {
                    $Src = Join-Path $Prof.FullName $F
                    if (Test-Path $Src) { 
                        Copy-Item $Src -Destination (Join-Path $Dest "$($Prof.Name)_$F") -ErrorAction SilentlyContinue 
                    }
                }
            }
        }
    }
} catch {
    Write-Log -Level "ERROR" -Message "Error collecting Browser Artifacts: $_"
}
