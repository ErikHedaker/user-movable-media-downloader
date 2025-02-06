$Require = @(
    [PSCustomObject]@{
        Uri    = 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-lgpl.zip'
        Name   = 'ffmpeg'
        Filter = 'ff*.exe'
        Pass   = { $PSItem | Export-Archive }
        Path   = ''
    },
    [PSCustomObject]@{
        Uri    = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'
        Name   = 'yt-dlp'
        Filter = 'yt-dlp.exe'
        Pass   = { $PSItem }
        Path   = ''
    }
)

if ($Require | Test-MissingCommand) {
    Clear-HostApp
    $tmp = Initialize-Directory '.\tmp' | Clear-Directory -PassThru
    $lib = Initialize-Directory '.\lib' | Clear-Directory -PassThru
    $Require | Request-App $tmp | Move-Files $lib | Add-EnvPathUser
    Clear-Directory $tmp
}