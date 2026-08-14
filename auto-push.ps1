$ErrorActionPreference = "Stop"
$watchDir = $PSScriptRoot
$busy = $false

function Test-Ignored($path) {
    if ($path -like "*\.git\*") { return $true }
    if ($path -eq (Join-Path $watchDir "auto-push.ps1")) { return $true }
    if ($path -like "*\auto-push.ps1") { return $true }
    return $false
}

function Invoke-AutoPush {
    if ($busy) { return }
    $busy = $true
    try {
        Start-Sleep -Seconds 3
        Set-Location $watchDir
        git add -A
        $status = git status --porcelain
        if ($status) {
            git commit -m "Auto-commit: $((Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))"
            git push origin main
            Write-Host "[auto-push] Pushed at $(Get-Date -Format 'HH:mm:ss')"
        } else {
            Write-Host "[auto-push] No changes to push"
        }
    } catch {
        Write-Host "[auto-push] ERROR: $_"
    } finally {
        $busy = $false
    }
}

$fsw = New-Object System.IO.FileSystemWatcher
$fsw.Path = $watchDir
$fsw.Filter = "*.*"
$fsw.IncludeSubdirectories = $true
$fsw.EnableRaisingEvents = $true

Register-ObjectEvent $fsw "Created" -Action {
    if (Test-Ignored $Event.SourceEventArgs.FullPath) { return }
    Invoke-AutoPush
} | Out-Null

Register-ObjectEvent $fsw "Changed" -Action {
    if (Test-Ignored $Event.SourceEventArgs.FullPath) { return }
    Invoke-AutoPush
} | Out-Null

Register-ObjectEvent $fsw "Renamed" -Action {
    if (Test-Ignored $Event.SourceEventArgs.FullPath) { return }
    Invoke-AutoPush
} | Out-Null

Register-ObjectEvent $fsw "Deleted" -Action {
    if (Test-Ignored $Event.SourceEventArgs.FullPath) { return }
    Invoke-AutoPush
} | Out-Null

Write-Host "[auto-push] Watching $watchDir ... Press Ctrl+C to stop."
while ($true) { Start-Sleep -Seconds 5 }