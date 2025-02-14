param([string]$ProjectRoot = $(throw 'ProjectRoot script parameter is required'))

try {
    Set-Location $ProjectRoot
    Set-Variable ErrorActionPreference Inquire
    Set-Variable ProgressPreference SilentlyContinue
    . .\src\functions $ProjectRoot
    # .\test\src\reverse_initialization.ps1
    # .\test\src\clear_directory_downloads.ps1
    $Resource = Get-RequiredResource

    if ($Resource | Test-InvalidCommand) {
        Clear-HostApp
        "Starting installation...`n"
        $tmp = Initialize-Directory 'tmp' | Clear-Directory
        $lib = Initialize-Directory 'lib' | Clear-Directory | Add-UserEnvPath
        $Resource | Request-Resource $tmp | Expand-Resource | Move-Resource $lib
        $tmp | Clear-Directory | Out-Null
    }

    $History = @()
    $Directory = Get-UserDownloadDirectory
    $Arguments = Get-UserDownloadArguments

    while ($true) {
        Clear-HostApp
        Format-DownloadHistory $History
        $URL = Read-Host 'Enter URL'
        & yt-dlp @Arguments -o "$Directory\%(title)s.%(ext)s" $URL | Tee-Object -Variable Output
        $History += $Output -join "`n" | Select-FileDestination
    }
} catch {
    Exit-AppFailure $_
}