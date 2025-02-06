param(
    $ProjectRoot = $(throw 'ProjectRoot is required')
)

try {
    Set-Location $ProjectRoot
    Set-Variable ErrorActionPreference Stop
    Set-Variable ProgressPreference SilentlyContinue
    . .\src\Functions $ProjectRoot
    .\src\Initialize-App
    .\src\Start-App
} catch {
    Write-Host "`nCaught error:`n`n$_`n" -ForegroundColor DarkYellow
    Pause
}