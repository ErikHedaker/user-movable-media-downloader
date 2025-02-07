param($ProjectRoot = $(throw 'ProjectRoot is required'))

function Clear-HostApplication {
    [CmdletBinding()]
    param()

    process {
        $Application = Split-Path $ProjectRoot -Leaf
        Clear-Host
        Write-Host "Application[$Application]`n"
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

        if ($Path -notlike "$ProjectRoot*") {
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
        )][string]$Uri,
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][PSCustomObject]$Resource
    )

    begin {
        $Retry = 4
        $Delay = 500
    }

    process {
        $Destination = '{0}\{1}{2}' -f $Parent, $Resource.Name, [System.IO.Path]::GetExtension($Uri)
        $WebClient = New-Object System.Net.WebClient
        $RetryAttempt = $Retry

        while ($RetryAttempt -gt 0) {
            try {
                Write-Host "Downloading [URL]:`n[$Uri]`n`nPlease wait...`n"
                $WebClient.DownloadFile($Uri, $Destination)
                Write-Host "Downloaded [File]:`n[$Destination]"
                break
            } catch {
                Write-Host "Error: $_"
                Start-Sleep -Milliseconds $Delay
                $RetryAttempt--
            }
        }

        $Resource.Path = $Destination
        $Resource
    }
}
function Expand-IfArchive {
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

    begin {
        $Ext = @('.zip')
    }

    process {
        if ($Ext -contains [System.IO.Path]::GetExtension($Path)) {
            $Parent = Split-Path $Path -Parent
            $DestinationPath = "$Parent\$Name"
            Write-Host "Extracting [Archive]:`n[$Path]`n`nPlease wait...`n"
            Expand-Archive $Path $DestinationPath -Force
            Write-Host "Extracted [Directory]:`n[$DestinationPath]"
            $Resource.Path = $DestinationPath
        }

        $Resource
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
        )][string]$Path
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
            Write-Host "Updated user PATH environment variable to include [Path]:`n[$Entry]"
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
        Clear-HostApplication
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
        Clear-HostApplication
        $Options.Keys | ForEach-Object { '[{0}] {1}' -f $_, $Options[$_].Description } | Write-Host
        Write-Host ''

        do {
            $Select = Read-Host 'Select'
        } while ($null -eq $Options[$Select])

        $Options[$Select].Arguments
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

<#
function Select-SuccessfulDownload {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string[]]$Downloads,
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][string[]]$Capture
    )

    begin {
        $Pattern = [PSCustomObject]@{
            Destination = ''
            Success     = ''
        }
    }

    process {
        $Success = $Capture -match $Pattern.Success
    }
}
#>