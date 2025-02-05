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
        Write-Host "Error: $Message"
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
            Exit-ProjectError "Path[$Path] is outside the project root path"
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
            Write-Host "Added required Directory[$Path]"
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
        [switch]$WhatIf
    )

    process {
        Write-VerboseFunction

        if (Test-Path $Path) {
            Get-ChildItem $Path | Remove-Item -Recurse -WhatIf:$WhatIf
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
        $Ext = [System.IO.Path]::GetExtension($Uri)
        $File = $App.Name + $Ext
        $Destination = "$Parent\$File"
        $RemainingRetry = $Retry

        while ($RemainingRetry -gt 0) {
            try {
                Write-VerboseVariable @{ Destination = $Destination; Uri = $Uri }
                Write-Host "Starting Download[$Uri]:`n`nPlease wait...`n"
                # # Start-BitsTransfer -Source $Uri -Destination $Destination -Priority Foreground
                # # Invoke-RestMethod -ContentType 'application/octet-stream' -Uri $Uri -OutFile $Destination | Out-Null
                # Invoke-WebRequest -Uri $Uri -OutFile $Destination | Out-Null
                # (New-Object System.Net.WebClient).DownloadFile($Uri, $Destination)
                curl.exe -L -o $Destination $Uri
                Write-Host "Finished Download[$Destination]"
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

    begin {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
    }

    process {
        Write-VerboseFunction
        $Parent = Split-Path $Path -Parent
        $Name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        $Extract = "$Parent\$Name"
        #Expand-Archive $Path -DestinationPath C:\Reference
        <#
        $dirname = (Get-Item $file).Basename
        New-Item -Force -ItemType directory -Path $dirname
        expand-archive $file -OutputPath $dirname -ShowProgress
        #>
        #[System.IO.Compression.ZipFile]::ExtractToDirectory($Path, $Extract)
        $App.Path = $Extract
        Write-VerboseVariable @{ Parent = $Parent; Name = $Name; Extract = $Extract }
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
            Write-Host "Moving directory from Source to Destination:`n[$Source]`n[$Destination]"
            Move-Item -Path $Source $Destination -Force
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
            Write-Host "Added Path[$Entry] to user environment variables"
        }
    }
}
function Test-AppExist {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Name
    )

    process {
        Write-VerboseFunction
        $Exist = [bool](Get-Command $Name -CommandType Application -ErrorAction Ignore)
        Write-VerboseVariable @{ Exist = $Exist }
        $Exist
    }
}
function Test-AnyAppMissing {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName
        )][string]$Name
    )

    begin {
        $Exists = [System.Collections.Generic.List[bool]]::new()
    }

    process {
        Write-VerboseFunction
        $Exists.Add((Test-AppExist $Name))
    }

    end {
        $Exists -Contains $false
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
        $Prompt = 'Opening [System.Windows.Forms.FolderBrowserDialog] for selecting download destination'
        Write-Host $Prompt
        $UserSelectDirectory.Description = 'Select download destination'
        $Result = $UserSelectDirectory.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK

        if ($Result) {
            $Path = $UserSelectDirectory.SelectedPath
            Write-Host "User selected download Path[$Path]"
        } else {
            Write-Host "Invalid path selected. Using default Path[$Path]"
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