param($ProjectRoot = $(throw 'ProjectRoot is required'))

try {
    Set-Location $ProjectRoot
    Set-Variable ErrorActionPreference Stop
    Set-Variable ProgressPreference SilentlyContinue
    . .\src\app\functions.ps1 $ProjectRoot
    # .\test\app\reverse_initialization.ps1
    # .\test\app\clear_directory_downloads.ps1
    .\src\app\initialize.ps1
    .\src\app\run.ps1
} catch {
    "`nCaught error:`n`n$_`n" |
        Write-Host -ForegroundColor DarkYellow
    Pause
}