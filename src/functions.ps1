param([string]$ProjectRoot = $(throw 'ProjectRoot script parameter is required'))
function Exit-AppFailure {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )]$Err,
        [Parameter(
            ValueFromPipeline
        )]$Message
    )

    process {
        $Output = "`n`tApplication Error`n"

        if ($null -ne $Message) {
            $Output += $Message
        }

        if ($null -ne $Err) {
            $Output += "
            Message:`n[{0}]
            FullyQualifiedErrorId:`n[{1}]
            CategoryInfo:`n[{2}]
            CommandInvocation:`n[{3}]" -f
            $Err.Exception.Message,
            $Err.FullyQualifiedErrorId,
            $Err.CategoryInfo,
            ($Err.Exception.CommandInvocation |
                Format-List -Force -Expand Both |
                    Out-String)
        }

        $Output | Write-Host -ForegroundColor DarkYellow
        Pause
        [System.Environment]::Exit(0)
    }
}
function Resolve-ProjectPath {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Path
    )

    process {
        try {
            $Path = Resolve-Path $Path
        } catch {
            Exit-AppFailure $_
        }

        if ($Path -notlike "$ProjectRoot*") {
            "`nOnly paths within [ProjectRoot] are permitted, [Path] is not:`n[{0}]`n[{1}]`n" -f
            $ProjectRoot, $Path | Exit-AppFailure
        }

        $Path
    }
}
function Get-RequiredResource {
    [CmdletBinding()]
    param()

    begin {
        $Resource = @(
            [PSCustomObject]@{
                Path   = 'https://github.com/BtbN/FFmpeg-Builds/releases' +
                '/download/latest/ffmpeg-master-latest-win64-lgpl.zip'
                Name   = 'ffmpeg'
                Filter = 'ff*.exe'
            },
            [PSCustomObject]@{
                Path   = 'https://github.com/yt-dlp/yt-dlp/releases' +
                '/latest/download/yt-dlp.exe'
                Name   = 'yt-dlp'
                Filter = 'yt-dlp.exe'
            }
        )
    }

    process {
        $Resource
    }
}
function Clear-HostApp {
    [CmdletBinding()]
    param()

    process {
        $Application = Split-Path $ProjectRoot -Leaf
        Clear-Host
        "Application[{0}]`n" -f
        $Application | Out-Host
    }
}
function Initialize-Directory {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Path
    )

    process {
        if (-not (Test-Path $Path)) {
            $Path = (New-Item $Path -ItemType Directory).FullName
            "Added [Directory]:`n[{0}]" -f $Path | Out-Host
        }

        Resolve-ProjectPath $Path
    }
}
function Clear-Directory {
    [CmdletBinding()]
    param(
        [parameter(
            Mandatory,
            ValueFromPipeline
        )][string]$Path,
        [switch]$WhatIf
    )

    process {
        if (Test-Path $Path) {
            Get-ChildItem $Path | Remove-Item -Recurse -WhatIf:$WhatIf
            "Cleared [Directory]:`n[{0}]" -f $Path | Out-Host
        }

        $Path
    }
}
function Get-EnvPath {
    [CmdletBinding()]
    param(
        [switch]$String
    )

    process {
        $EnvPath = [ordered]@{
            Machine = [System.Environment]::GetEnvironmentVariable(
                'Path', 'Machine'
            ).Trim(';').Split(';')
            User    = [System.Environment]::GetEnvironmentVariable(
                'Path', 'User'
            ).Trim(';').Split(';')
        }

        if ($String) {
            $EnvPath.Machine +
            $EnvPath.User -join ';'
        } else {
            $EnvPath
        }
    }
}
function Remove-UserEnvPath {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Pattern
    )

    process {
        $Filtered = (Get-EnvPath).User | Where-Object { $_ -notlike $Pattern }
        $Value = $Filtered -join ';'
        [System.Environment]::SetEnvironmentVariable('Path', $Value, 'User')
        $Env:Path = Get-EnvPath -String
    }
}
function Add-UserEnvPath {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][string]$Path
    )

    process {
        Remove-UserEnvPath "*$Path*"
        $UserEnvPath = (Get-EnvPath).User + $Path
        $Appended = $UserEnvPath -join ';'
        [System.Environment]::SetEnvironmentVariable('Path', $Appended, 'User')
        $Env:Path = Get-EnvPath -String
        "Appended [Path] to User Environment Variable:`n[{0}]" -f $Path | Out-Host
        $Path
    }
}
function Request-Resource {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Parent,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )][string]$Path,
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][PSCustomObject]$Resource
    )

    process {
        $WebClient = New-Object System.Net.WebClient
        $Destination = '{0}\{1}{2}' -f
        $Parent, $Resource.Name, [System.IO.Path]::GetExtension($Path)

        for ($Retry = 4; $Retry -gt 0; $Retry--) {
            try {
                "Downloading [URL]:`n[{0}]`n`nPlease wait...`n" -f
                $Path | Out-Host
                $WebClient.DownloadFile($Path, $Destination)
                "Downloaded [File]:`n[{0}]" -f
                ($Resource.Path = $Destination) | Out-Host
                return $Resource
            } catch {
                'Error: {0}' -f $_ | Out-Host
                Start-Sleep -Milliseconds 500
            }
        }
    }
}
function Expand-Resource {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )][string]$Path,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )][string]$Name,
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][PSCustomObject]$Resource
    )

    process {
        if ([System.IO.Path]::GetExtension($Path) -eq '.zip') {
            $DestinationPath = '{0}\{1}' -f (Split-Path $Path -Parent), $Name
            "Extracting [Archive]:`n[{0}]`n`nPlease wait...`n" -f
            $Path | Out-Host
            Expand-Archive $Path $DestinationPath -Force
            "Extracted [Directory]:`n[{0}]" -f
            $DestinationPath | Out-Host
            $Resource.Path = $DestinationPath
        }

        $Resource
    }
}
function Move-Resource {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Destination,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )][string]$Filter,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )][string]$Path
    )

    process {
        Get-ChildItem $Path $Filter -Recurse | ForEach-Object {
            $Source = $PSItem.FullName
            Move-Item -Path $Source $Destination -Force
            "Moved [Source] to [Destination]:`n[{0}]`n[{1}]" -f
            $Source, $Destination | Out-Host
        }
    }
}
function Test-InvalidCommand {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )][string]$Name
    )

    begin {
        $Resource = [System.Collections.Generic.List[bool]]::new()
    }

    process {
        $Resource.Add([bool](Get-Command $Name -CommandType Application -ErrorAction Ignore))
    }

    end {
        $Resource -contains $false
    }
}
function Get-UserDownloadDirectory {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )][string]$Path = "$Env:UserProfile\Downloads"
    )

    begin {
        Add-Type -AssemblyName System.Windows.Forms
    }

    process {
        Clear-HostApp
        $DirectoryPrompt = New-Object System.Windows.Forms.FolderBrowserDialog
        $DirectoryPrompt.ShowNewFolderButton = $true
        $DirectoryPrompt.SelectedPath = $Path
        $DirectoryPrompt.Description = 'Select download path:'
        'Opening [{0}] to select download path...' -f
        $DirectoryPrompt.GetType().Name | Out-Host
        $Result = $DirectoryPrompt.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK

        if ($Result) {
            $DirectoryPrompt.SelectedPath
        } else {
            $Path
        }
    }
}
function Get-UserDownloadArguments {
    [CmdletBinding()]
    param()

    begin {
        $Select = $null
        $Options = [ordered]@{
            '1' = [PSCustomObject]@{
                Description = 'Download video'
                Arguments   = @('-S', 'ext')
            }
            '2' = [PSCustomObject]@{
                Description = 'Download audio only'
                Arguments   = @('-x', '--audio-format', 'mp3', '--audio-quality', '0')
            }
        }
    }

    process {
        Clear-HostApp
        $Options.Keys |
            ForEach-Object { '[{0}] {1}' -f $_, $Options[$_].Description } -End { '' } |
                Out-Host

        do {
            $Select = Read-Host 'Select'
        } while ($null -eq $Options[$Select])

        $Options[$Select].Arguments
    }
}
function Format-DownloadHistory {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )][string[]]$Downloads = @()
    )

    process {
        if ($Downloads.Count -gt 0) {
            'Download history:'

            for ($i = 0; $i -lt $Downloads.Count; $i++) {
                '> {0,-2} = [{1}]' -f
                ($i + 1), $Downloads[$i]
            }

            ''
        }
    }
}
function Get-MediaExtension {
    [CmdletBinding()]
    param()

    begin {
        $ExtVideo = @('mp4', 'mov', 'webm', 'flv')
        $ExtAudio = @('m4a', 'aac', 'mp3', 'ogg', 'opus', 'webm')
    }

    process {
        $ExtVideo +
        $ExtAudio
    }
}
function Select-FileDestination {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][string]$Text
    )

    begin {
        $Pattern = '\s*Destination: (?<Path>\S.+?\.(?:{0}))\s*' -f
        ((Get-MediaExtension) -join '|')
    }

    process {
        $Result = $Text | Select-String $Pattern -AllMatches

        if ($Result) {
            $Result.Matches[-1].Groups['Path']
        }
    }
}