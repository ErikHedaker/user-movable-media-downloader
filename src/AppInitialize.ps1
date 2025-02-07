$Resource = @(
    [PSCustomObject]@{
        Uri    = 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-lgpl.zip'
        Name   = 'ffmpeg'
        Filter = 'ff*.exe'
        Path   = $null
    },
    [PSCustomObject]@{
        Uri    = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'
        Name   = 'yt-dlp'
        Filter = 'yt-dlp.exe'
        Path   = $null
    }
)

if ($Resource | Test-MissingCommand) {
    Clear-HostApplication
    $tmp = Initialize-Directory '.\tmp' | Clear-Directory -PassThru
    $lib = Initialize-Directory '.\lib' | Clear-Directory -PassThru
    $Resource | Request-Resource $tmp | Expand-IfArchive | Move-Files $lib | Add-EnvPathUser
    Clear-Directory $tmp
}