param(
    $ProjectRoot = $(throw 'ProjectRoot is required')
)

function Clear-HostApp {
    [CmdletBinding()]
    param()

    process {
        $App = Split-Path $ProjectRoot -Leaf
        Clear-Host
        Write-Host "App[$App]`n"
    }
}
function Test-ProjectPath {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Path
    )

    process {
        $Path -like "$ProjectRoot*"
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
        $Path = Resolve-Path $Path

        if (-not (Test-ProjectPath $Path)) {
            $Err = "`nOnly paths within [ProjectRoot] are permitted, [Path] is not:`n[$ProjectRoot]`n[$Path]`n"
            Write-Host $Err -ForegroundColor DarkYellow
            Pause
            Exit 1
        }

        $Path
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
            Write-Host "Added [Directory]:`n[$Path]"
        }

        Resolve-ProjectPath $Path
    }
}
function Clear-Directory {
    [CmdletBinding()]
    param(
        [parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline
        )][string]$Path,
        [switch]$WhatIf,
        [switch]$PassThru
    )

    process {
        if (Test-Path $Path) {
            Get-ChildItem $Path | Remove-Item -Recurse -WhatIf:$WhatIf
            Write-Host "Cleared [Directory]:`n[$Path]"
        }

        if ($PassThru) {
            $Path
        }
    }
}
function Request-App {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Parent,
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )][string]$Uri,
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][PSCustomObject]$App
    )

    begin {
        $Retry = 4
        $Delay = 500
    }

    process {
        $WebClient = New-Object System.Net.WebClient
        $Ext = [System.IO.Path]::GetExtension($Uri)
        $File = $App.Name + $Ext
        $Destination = "$Parent\$File"
        $RemainingRetry = $Retry

        while ($RemainingRetry -gt 0) {
            try {
                Write-Host "Starting [Download]:`n[$Uri]`n`nPlease wait...`n"
                $WebClient.DownloadFile($Uri, $Destination)
                Write-Host "Finished [Download]:`n[$Destination]"
                break
            } catch {
                Write-Host "Error: $_"
                Start-Sleep -Milliseconds $Delay
                $RemainingRetry--
            }
        }

        $App.Path = $Destination
        $App.Pass.Invoke()
    }
}
function Export-Archive {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )][string]$Path,
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][PSCustomObject]$App
    )

    process {
        $Parent = Split-Path $Path -Parent
        $Name = $App.Name
        $DestinationPath = "$Parent\$Name"
        Expand-Archive $Path $DestinationPath -Force
        Write-Host "Extracted [Archive] to [Directory]:`n[$Path]`n[$DestinationPath]"
        $App.Path = $DestinationPath
        $App
    }
}
function Move-Files {
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
        )][string]$Path,
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][PSCustomObject]$App
    )

    process {
        Get-ChildItem $Path $Filter -Recurse | ForEach-Object {
            $Source = $PSItem.FullName
            Move-Item -Path $Source $Destination -Force
            Write-Host "Moved [Source] to [Destination]:`n[$Source]`n[$Destination]"
        }
        $Destination
    }
}
function Get-EnvPath {
    [CmdletBinding()]
    param()

    process {
        ('{0};{1}' -f
        [System.Environment]::GetEnvironmentVariable('Path', 'Machine'),
        [System.Environment]::GetEnvironmentVariable('Path', 'User'))
    }
}
function Add-EnvPathUser {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][string]$Entry
    )

    process {
        if ((Get-EnvPath) -notlike "*$Entry*") {
            $Updated = '{0}{1};' -f [System.Environment]::GetEnvironmentVariable('Path', 'User'), $Entry
            [System.Environment]::SetEnvironmentVariable('Path', $Updated, 'User')
            $Env:Path = Get-EnvPath
            Write-Host "Added [Path] to user environment variables:`n[$Entry]"
        }
    }
}
function Test-MissingCommand {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )][string]$Name
    )

    begin {
        $Required = [System.Collections.Generic.List[bool]]::new()
    }

    process {
        $Required.Add([bool](Get-Command $Name -CommandType Application -ErrorAction Ignore))
    }

    end {
        $Required -contains $false
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
        $UserSelectDirectory = New-Object System.Windows.Forms.FolderBrowserDialog
        $UserSelectDirectory.ShowNewFolderButton = $true
        $UserSelectDirectory.SelectedPath = $Path
        $UserSelectDirectory.Description = 'Select download directory'
        Write-Host 'Showing [System.Windows.Forms.FolderBrowserDialog] to select download directory...'
        $Result = $UserSelectDirectory.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK

        if ($Result) {
            $UserSelectDirectory.SelectedPath
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
        $Arguments = [ordered]@{
            '1' = @(
                'Download video',
                @('-S', 'ext')
            )
            '2' = @(
                'Download audio only',
                @('-x', '--audio-format', 'mp3', '--audio-quality', '0')
            )
        }
    }

    process {
        Clear-HostApp
        $Arguments.Keys | ForEach-Object { '[{0}] {1}' -f $_, $Arguments[$_][0] } | Write-Host
        Write-Host ''

        do {
            $Select = Read-Host 'Select'
        } while ($null -eq $Arguments[$Select])

        $Arguments[$Select][1]
    }
}
function Write-PreviousDownloads {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )][string[]]$Downloads = @()
    )

    process {
        if ($Downloads.Count -gt 0) {
            Write-Host 'Downloads completed:'

            for ($i = 0; $i -lt $Downloads.Count; $i++) {
                Write-Host ("[{0}`t- {1}]" -f ($i + 1), $Downloads[$i])
            }

            Write-Host ''
        }
    }
}