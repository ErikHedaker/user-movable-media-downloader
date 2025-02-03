. .\src\functions.ps1

function Initialize-ProjectApplication {
    [CmdletBinding()]
    param()

    begin {
        $Applications = @(
            [PSCustomObject]@{
                Uri    = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe'
                Name   = 'yt-dlp'
                Path   = ''
                Filter = 'yt-dlp.exe'
                Pass   = { $PSItem }
            },
            [PSCustomObject]@{
                Uri    = 'https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-lgpl.zip'
                Name   = 'ffmpeg'
                Path   = ''
                Filter = 'ff*.exe'
                Pass   = { $PSItem | Export-Archive }
            },
            [PSCustomObject]@{
                Uri    = 'https://github.com/ip7z/7zip/releases/latest/download/7zr.exe'
                Name   = '7zr'
                Path   = ''
                Filter = '7zr.exe'
                Pass   = { $PSItem }
            }
        )
    }

    process {
        $MyInvocation.MyCommand.Name | Write-Host
        Set-Location "$PSScriptRoot\.."
        Set-Variable ProgressPreference SilentlyContinue
        Set-Variable VerbosePreference Continue
        Set-Variable ErrorActionPreference Inquire
        #$Unavailable = $_ | Test-AppMissing
        #if ()

        $tmp = Initialize-Directory '.\tmp'
        $lib = Initialize-Directory '.\lib'
        $Applications | Request-App $tmp | Move-Files $lib | Add-EnvPathUser
    }

    end {
        Clear-Directory $tmp
    }
}