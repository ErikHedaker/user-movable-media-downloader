param($ProjectRoot = $(throw 'ProjectRoot is required'))

try {
    Set-Location $ProjectRoot
    Set-Variable ErrorActionPreference Stop
    Set-Variable ProgressPreference SilentlyContinue
    . .\src\app\Functions $ProjectRoot
    # .\test\app\ReverseInitialization
    # .\test\app\ClearDirectoryDownloads
    .\src\app\Initialize
    .\src\app\Start
} catch {
    Write-Host "`nCaught error:`n`n$_`n" -ForegroundColor DarkYellow
    Pause
}