$Directory = Get-UserDownloadDirectory
$Arguments = Get-UserDownloadArguments
$Completed = @()

while ($true) {
    Clear-HostApp
    Write-DownloadFiles $Completed
    $URL = Read-Host 'Enter URL'
    #$Capture = $null
    & yt-dlp @Arguments -o "$Directory\%(title)s.%(ext)s" $URL #| Tee-Object -Variable Capture
    $Completed += $URL
    #Write-Host "`nCapture value:`n`n$Capture`n"
    #$Completed += $Capture | Select-Download | Format-Download
}