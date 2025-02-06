$Directory = Get-UserDownloadDirectory
$Arguments = Get-UserDownloadArguments
$Downloads = @()

while ($true) {
    Clear-HostApp
    Write-PreviousDownloads $Downloads
    $URL = Read-Host "Enter URL"
    & yt-dlp @Arguments -o "$Directory\%(title)s.%(ext)s" $URL
    $Downloads += $URL
}