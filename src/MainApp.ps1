param($ProjectRoot = $(throw 'ProjectRoot is required'))

try {
    Set-Location $ProjectRoot
    Set-Variable ErrorActionPreference Stop
    Set-Variable ProgressPreference SilentlyContinue
    . .\src\FunctionsApp $ProjectRoot
    # .\test\src\reverse_initialization.ps1
    # .\test\src\clear_directory_downloads.ps1
    $Resource = Get-RequiredResource

    if ($Resource | Test-MissingCommand) {
        Clear-HostApp
        Write-Host 'Starting installation...'
        $tmp = Initialize-Directory '.\tmp' | Clear-Directory -PassThru
        $lib = Initialize-Directory '.\lib' | Clear-Directory -PassThru
        $Resource |
            Request-Resource $tmp |
                Expand-ArchiveFileExt |
                    Move-FilterFiles $lib |
                        Add-EnvPathUser
        Clear-Directory $tmp
    }

    $Directory = Get-UserDownloadDirectory
    $Arguments = Get-UserDownloadArguments
    $History = @()

    while ($true) {
        Clear-HostApp
        Format-DownloadHistory $History
        $URL = Read-Host 'Enter URL'
        & yt-dlp @Arguments -o "$Directory\%(title)s.%(ext)s" $URL | Tee-Object -Variable Output
        $History += $Output -join "`n" | Select-FileDestination
    }
} catch {
    "`nError:`n`n$_`n" | Exit-AppFailure
}