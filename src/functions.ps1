function Protect-RootPath {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline,
            Mandatory
        )][string]$Path
    )

    process {
        $MyInvocation.MyCommand.Name | Write-Verbose
        $PSBoundParameters | Write-Verbose
        $Path = Resolve-Path $Path
        $Root = [System.IO.Path]::GetPathRoot($Path)
        $Test = $Path -eq $Root
        Write-Verbose "Path is Root: $Test"

        if ($Test) {
            #Throw "Path[$Path] is a system root directory which can lead to unwanted system changes"
            Write-Host "Path[$Path] is a system root directory which can lead to unwanted system changes"
            Exit 1
        }
        else {
            Write-Host "Path[$Path] is valid"
            $Path
        }
    }
}

function Resolve-ProjectPath {
    param (
        [string]$Path
    )

    # Resolve the parent project directory
    $ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path

    # Resolve the absolute path of the target directory
    $ResolvedPath = Resolve-Path -Path $Path -ErrorAction Stop

    # Check if the target path is within the project root
    if (-not ($ResolvedPath -like "$ProjectRoot*")) {
        Write-Error "Unsafe operation: Attempted access outside of project directory! ($ResolvedPath)"
        exit 1  # Stop execution immediately
    }

    return $ResolvedPath
}

# Example usage before performing delete operations
#$SafeLibPath = Ensure-SafePath "$PSScriptRoot\..\lib"
#Remove-Item -Path $SafeLibPath\* -Recurse -Force


function Clear-Directory {
    [CmdletBinding()]
    param(
        [parameter(
            Position = 0,
            ValueFromPipeline
        )][string]$Path = $PSScriptRoot,
        [switch]$WhatIf
    )

    process {
        Write-Host "$($MyInvocation.MyCommand.Name) Path[$Path]"
        $PSBoundParameters | Write-Verbose

        if (Test-Path $Path) {
            Get-ChildItem $Path | Remove-Item -Recurse -WhatIf:$WhatIf
        }
    }
}

function Clear-DirectorySAFER {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [parameter(Position = 0)]
        [string]$Path = $PSScriptRoot,

        [switch]$WhatIf
    )

    process {
        Write-Host "$($MyInvocation.MyCommand.Name) Path[$Path]"
        $PSBoundParameters | Write-Verbose

        # Resolve project root (assumes script is inside the project)
        $ProjectRoot = (Resolve-Path "$PSScriptRoot\..").Path
        $ResolvedPath = Resolve-Path -Path $Path -ErrorAction Stop

        # Ensure the path is within the project directory
        if (-not ($ResolvedPath -like "$ProjectRoot*")) {
            Write-Error "Unsafe operation: Attempted to clear a directory outside of the project! ($ResolvedPath)"
            exit 1
        }

        if (Test-Path $ResolvedPath) {
            # Get child items to determine if directory is empty
            $Items = Get-ChildItem -Path $ResolvedPath

            if ($Items) {
                # Ask for confirmation before deleting everything
                $Confirm = Read-Host "Are you sure you want to delete all contents in '$ResolvedPath'? (y/n)"
                if ($Confirm -match "^[yY]$") {
                    # Use -WhatIf:$WhatIf to allow simulation mode
                    Remove-Item -Path $Items.FullName -Recurse -Force -WhatIf:$WhatIf
                }
                else {
                    Write-Host "Operation canceled."
                }
            }
            else {
                Write-Host "Directory '$ResolvedPath' is already empty."
            }
        }
        else {
            Write-Host "Directory '$ResolvedPath' does not exist."
        }
    }
}


function Initialize-Directory {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )][string]$Path = $PSScriptRoot,
        [switch]$WhatIf
    )

    process {
        $MyInvocation.MyCommand.Name | Write-Verbose
        $PSBoundParameters | Write-Verbose

        if (-Not (Test-Path $Path)) {
            $Path = (New-Item $Path -ItemType Directory -WhatIf:$WhatIf).FullName
            Write-Host "Added Directory[$Path]"
        }

        $Path | Protect-RootPath | Clear-Directory -WhatIf:$WhatIf
        $Path
    }
}
function Request-App {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )][string]$Parent = $PSScriptRoot,
        [Parameter(
            ValueFromPipelineByPropertyName
        )][string]$Uri,
        [Parameter(
            ValueFromPipeline
        )][PSCustomObject]$App
    )

    begin {
        $Retry = 5
        $Delay = 200
    }

    process {
        Write-Host "$($MyInvocation.MyCommand.Name) Uri[$Uri]"
        $PSBoundParameters | Write-Verbose
        $Name = [System.IO.Path]::GetFileName($Uri)
        $Path = "$Parent\$Name"
        $RetriesLeft = $Retry

        while ($RetriesLeft -gt 0) {
            try {
                Invoke-WebRequest $Uri -OutFile $Path | Out-Null
                break
            }
            catch {
                Write-Host "Error: $_"
                Start-Sleep -Milliseconds $Delay
            }
        }

        $App.Path = $Path
        $App.Pass.Invoke()
    }
}

function Export-Archive {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipelineByPropertyName
        )][string]$Path = $PSScriptRoot,
        [Parameter(
            ValueFromPipeline
        )][PSCustomObject]$App
    )

    begin {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
    }

    process {
        Write-Host "$($MyInvocation.MyCommand.Name) Path[$Path]"
        $PSBoundParameters | Write-Verbose
        $Parent = Split-Path $Path -Parent
        $Name = [System.IO.Path]::GetFileNameWithoutExtension($Path)
        $Extract = "$Parent\$Name"
        #Expand-Archive -Path Draft.Zip -DestinationPath C:\Reference
        <#
        $dirname = (Get-Item $file).Basename
        New-Item -Force -ItemType directory -Path $dirname
        expand-archive $file -OutputPath $dirname -ShowProgress
        #>
        [System.IO.Compression.ZipFile]::ExtractToDirectory($Path, $Extract)
        $App.Path = $Extract
        $App
    }
}

function Move-Files {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )][string]$Destination = $PSScriptRoot,
        [Parameter(
            ValueFromPipelineByPropertyName
        )][string]$Filter,
        [Parameter(
            ValueFromPipelineByPropertyName
        )][string]$Path = $PSScriptRoot,
        [Parameter(
            ValueFromPipeline
        )][PSCustomObject]$App
    )

    process {
        Write-Host "$($MyInvocation.MyCommand.Name) Destination[$Destination]"
        $PSBoundParameters | Write-Verbose
        Get-ChildItem $Path $Filter -Recurse | ForEach-Object {
            $Source = $PSItem.FullName
            Write-Host "Moving Source[$Source] to Destination[$Destination]"
            Move-Item -Path $Source $Destination -Force
        }
        $Destination
    }
}

function Get-EnvPath {
    [CmdletBinding()]
    param()

    process {
        $MyInvocation.MyCommand.Name | Write-Verbose
        $Result = ('{0};{1}' -f
            [System.Environment]::GetEnvironmentVariable('Path', 'Machine'),
            [System.Environment]::GetEnvironmentVariable('Path', 'User'))
        Write-Verbose "Result[$Result]"
        $Result
    }
}

function Add-EnvPathUser {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline
        )][string]$Path = $PSScriptRoot
    )

    process {
        $MyInvocation.MyCommand.Name | Write-Verbose
        $PSBoundParameters | Write-Verbose

        if ((Get-EnvPath) -notlike "*$Path*") {
            $EnvPathUser = [System.Environment]::GetEnvironmentVariable('Path', 'User') + ";$Path"
            [System.Environment]::SetEnvironmentVariable('Path', $EnvPathUser, 'User')
            $Env:Path = Get-EnvPath
            Write-Host "Added user environment variable Path[$Path]"
        }
    }
}

function Test-AppMissing {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipelineByPropertyName
        )][string]$Name
    )

    process {
        $MyInvocation.MyCommand.Name | Write-Verbose
        $PSBoundParameters | Write-Verbose
        $Missing = -not [bool](Get-Command $Name -CommandType Application -ErrorAction Ignore)
        Write-Host "Is Command[$Name] unavailable in PATH[$Missing]"
        $Missing
    }
}

function Show-SelectDirectory() {
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
        $MyInvocation.MyCommand.Name | Write-Verbose
        $PSBoundParameters | Write-Verbose
        $UserSelectDirectory = New-Object System.Windows.Forms.FolderBrowserDialog
        $UserSelectDirectory.SelectedPath = $Path
        $UserSelectDirectory.ShowNewFolderButton = $true
        $UserSelectDirectory.Description = 'Select a destination directory for downloads:'
        $Result = $UserSelectDirectory.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK

        if ($Result) {
            $Path = $UserSelectDirectory.SelectedPath
            Write-Host "Selected Path[$Path]"
        }
        else {
            Write-Host "Invalid Path. Using default Path[$Path]"
        }

        $Path
    }
}