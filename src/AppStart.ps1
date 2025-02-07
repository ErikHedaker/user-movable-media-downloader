$Directory = Get-UserDownloadDirectory
$Arguments = Get-UserDownloadArguments
$Downloads = @()

while ($true) {
    Clear-HostApp
    Write-PreviousDownloads $Downloads
    $URL = Read-Host 'Enter URL'
    #$Capture = $null
    & yt-dlp @Arguments -o "$Directory\%(title)s.%(ext)s" $URL #| Tee-Object -Variable Capture
    #$Capture | Select-SuccessfulDownload $Downloads
    $Downloads += $URL
}