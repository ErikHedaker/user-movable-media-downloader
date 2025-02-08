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