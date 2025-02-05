param(
    $ProjectRoot = $(throw 'ProjectRoot is required')
)

function Write-VerboseFunction {
    [CmdletBinding()]
    param()

    process {
        $Stack = Get-PSCallStack
        $Name = $Stack[1].Command
        $Arguments = $Stack[1].Arguments
        Write-Verbose "$Name`n$Arguments"
    }
}
function Write-VerboseVariable {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromRemainingArguments
        )]$Arguments
    )

    process {
        $Arguments | Format-List -Force | Out-String | Write-Verbose
    }
}
function Exit-ProjectError {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Message
    )

    process {
        Write-VerboseFunction
        Write-Host "Fatal error:`n$Message" -ForegroundColor DarkYellow
        Pause
        Exit 1
    }
}
function Assert-ProjectPath {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Path
    )

    process {
        Write-VerboseFunction
        $Assert = $Path -Like "$ProjectRoot*"
        Write-VerboseVariable @{ Path = $Path; ProjectRoot = $ProjectRoot; Assert = $Assert }
        $Assert
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
        Write-VerboseFunction
        $Path = Resolve-Path $Path

        if (-Not (Assert-ProjectPath $Path)) {
            Exit-ProjectError "For safety, paths are only allowed within [ProjectRoot], [Path] is outside:`n[$ProjectRoot]`n[$Path]"
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
        Write-VerboseFunction

        if (-Not (Test-Path $Path)) {
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
        Write-VerboseFunction

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
        Write-VerboseFunction
        $WebClient = New-Object System.Net.WebClient
        $Ext = [System.IO.Path]::GetExtension($Uri)
        $File = $App.Name + $Ext
        $Destination = "$Parent\$File"
        $RemainingRetry = $Retry

        while ($RemainingRetry -gt 0) {
            try {
                Write-VerboseVariable @{ Destination = $Destination; Uri = $Uri }
                Write-Host "Starting [Download]:`n[$Uri]:`n`nPlease wait...`n"
                $WebClient.DownloadFile($Uri, $Destination)
                Write-Host "Finished [Download]:`n[$Destination]"
                break
            } catch {
                Write-Host "Error: $_"
                Start-Sleep -Milliseconds $Delay
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
        Write-VerboseFunction
        $Parent = Split-Path $Path -Parent
        $Name = $App.Name
        $DestinationPath = "$Parent\$Name"
        Expand-Archive $Path $DestinationPath -Force | Out-Host
        Write-Host "Extracted [Archive] to [Destination]:`n[$Path]`n[$DestinationPath]"
        Write-VerboseVariable @{ Parent = $Parent; Name = $Name; DestinationPath = $DestinationPath }
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
        Write-VerboseFunction
        Get-ChildItem $Path $Filter -Recurse | ForEach-Object {
            $Source = $PSItem.FullName
            Move-Item -Path $Source $Destination -Force
            Write-Host "Moved [Source] to [Destination]:`n[$Source]`n[$Destination]"
        }
        Write-VerboseVariable @{ Destination = $Destination }
        $Destination
    }
}
function Get-EnvPath {
    [CmdletBinding()]
    param()

    process {
        Write-VerboseFunction
        $EnvPathSystem = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
        $EnvPathUser = [System.Environment]::GetEnvironmentVariable('Path', 'User')
        $EnvPath = "$EnvPathSystem;$EnvPathUser"
        Write-VerboseVariable @{ EnvPathSystem = $EnvPathSystem; EnvPathUser = $EnvPathUser; EnvPath = $EnvPath }
        $EnvPath
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
        Write-VerboseFunction
        $Contain = (Get-EnvPath) -Like "*$Entry*"

        if (-Not $Contain) {
            $Updated = [System.Environment]::GetEnvironmentVariable('Path', 'User') + "$Entry;"
            [System.Environment]::SetEnvironmentVariable('Path', $Updated, 'User')
            $Env:Path = Get-EnvPath
            Write-Host "Added [Path] to user environment variables:`n[$Entry]"
        }
    }
}
function Test-AppAvailable {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Name
    )

    process {
        Write-VerboseFunction
        $Available = [bool](Get-Command $Name -CommandType Application -ErrorAction Ignore)
        Write-VerboseVariable @{ Available = $Available }
        $Available
    }
}
function Test-AppAnyUnavailable {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )][string]$Name
    )

    begin {
        $Available = [System.Collections.Generic.List[bool]]::new()
    }

    process {
        Write-VerboseFunction
        $Available.Add((Test-AppAvailable $Name))
    }

    end {
        $Available -Contains $false
    }
}
function Show-SelectDirectory {
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
        Write-VerboseFunction
        $UserSelectDirectory = New-Object System.Windows.Forms.FolderBrowserDialog
        $UserSelectDirectory.SelectedPath = $Path
        $UserSelectDirectory.ShowNewFolderButton = $true
        $Prompt = 'Opening [System.Windows.Forms.FolderBrowserDialog] to select download directory:'
        Write-Host $Prompt
        $UserSelectDirectory.Description = 'Select download directory'
        $Result = $UserSelectDirectory.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK

        if ($Result) {
            $Path = $UserSelectDirectory.SelectedPath
            Write-Host "User selected download [Directory]:`n[$Path]"
        } else {
            Write-Host "Invalid path selected. Using default [Directory]:`n[$Path]"
        }

        Write-VerboseVariable @{ Result = $Result; Path = $Path }
        $Path
    }
}
function Show-Downloads {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline
        )]$Download
    )

    begin {
        $Num = 0
    }

    process {
        Write-VerboseFunction
        $Download | ForEach-Object {
            $Num += 1

            if ($Num -eq 1) {
                'Completed downloads:'
            }

            ": $Num`t- $_"
        } | Write-Host
    }

    end {
        Write-Host ''
    }
}

function Show-SelectCommandArguments {
    [CmdletBinding()]
    param()

    process {
        $Prompt = "[1] Download video with audio`n[2] Download only audio`nChoice"
        $Commands = @{
            1 = @()
            2 = @('-x', '--audio-format', 'mp3', '--audio-quality', '0')
        }
        $Result = $null
        do {
            $Result = Read-Host $Prompt
        } while ($null -eq $Commands.$Result)

        $Commands.$Result
    }
}