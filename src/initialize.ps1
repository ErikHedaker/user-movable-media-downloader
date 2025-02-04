param(
    $ProjectRoot = $(throw 'ProjectRoot is required')
)

. .\src\functions.ps1 $ProjectRoot
function Initialize-ProjectApplication {
    [CmdletBinding()]
    param()

    begin {
        $Applications = @(
            [PSCustomObject]@{
                Uri    = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'
                Name   = 'yt-dlp'
                Filter = 'yt-dlp.exe'
                Pass   = { $PSItem }
                Path   = ''
            },
            [PSCustomObject]@{
                Uri    = 'https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-lgpl.zip'
                Name   = 'ffmpeg'
                Filter = 'ff*.exe'
                Pass   = { $PSItem | Export-Archive }
                Path   = ''
            }
            <#
            [PSCustomObject]@{
                Uri    = 'https://github.com/ip7z/7zip/releases/latest/download/7zr.exe'
                Name   = '7zr'
                Filter = '7zr.exe'
                Pass   = { $PSItem }
                Path   = ''
            }
            #>
        )
    }

    process {
        Write-FunctionVerbose

        if ($Applications | Test-AnyAppMissing) {
            $tmp = Initialize-Directory '.\tmp'
            $lib = Initialize-Directory '.\lib'
            Clear-Directory $tmp
            Clear-Directory $lib
            $Applications | Request-App $tmp | Move-Files $lib | Add-EnvPathUser
            Clear-Directory $tmp
        }
    }
}