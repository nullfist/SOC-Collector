param (
    [string]$CaseOutputDir,
    [string]$CaseID
)

Write-Log -Level "INFO" -Message "Compressing Evidence directory..."

try {
    # Get the parent directory of CaseOutputDir
    $ParentDir = Split-Path -Path $CaseOutputDir -Parent
    $ZipPath = Join-Path -Path $ParentDir -ChildPath "$CaseID.zip"

    # Compress the entire Case directory
    Compress-Archive -Path $CaseOutputDir -DestinationPath $ZipPath -Force -ErrorAction Stop
    
    # Calculate hash of the zip file
    $ZipHash = Get-FileHash -Path $ZipPath -Algorithm SHA256
    $ZipHashStr = $ZipHash.Hash
    
    # Write hash to a sidecar file
    $HashFile = Join-Path -Path $ParentDir -ChildPath "$CaseID.zip.sha256"
    "$ZipHashStr  $CaseID.zip" | Out-File -FilePath $HashFile -Encoding ASCII

    Write-Log -Level "STATUS" -Message "Successfully compressed evidence to $ZipPath"
    Write-Log -Level "STATUS" -Message "ZIP SHA256: $ZipHashStr"

} catch {
    Write-Log -Level "ERROR" -Message "Error compressing evidence: $_"
}
