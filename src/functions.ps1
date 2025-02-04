param(
    $ProjectRoot = $(throw 'ProjectRoot is required')
)

function Write-FunctionVerbose {
    [CmdletBinding()]
    param()

    process {
        $Stack = Get-PSCallStack
        $Name = $Stack[1].Command
        $Arguments = $Stack[1].Arguments
        Write-Verbose "$Name`n$Arguments"
    }
}
function Write-VariableVerbose {
    [CmdletBinding()]
    param(
        [Parameter(
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
            Position = 0
        )][string]$Message
    )

    process {
        Write-FunctionVerbose
        Write-Host "Error: $Message"
        Pause
        Exit 1
    }
}
function Assert-ParentPath {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Path,
        [Parameter(
            Mandatory,
            Position = 1
        )][string]$Parent
    )

    process {
        Write-FunctionVerbose
        $Assert = $Parent -eq (Split-Path $Path -Leaf)
        Write-VariableVerbose @{ Path = $Path; Parent = $Parent; Assert = $Assert }
        $Assert
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
        Write-FunctionVerbose
        $Assert = $Path -like "$ProjectRoot*"
        Write-VariableVerbose @{ Path = $Path; ProjectRoot = $ProjectRoot; Assert = $Assert }
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
        Write-FunctionVerbose
        $Path = Resolve-Path $Path

        if (-Not (Assert-ProjectPath $Path)) {
            Exit-ProjectError "Path[$Path] is outside the project root path"
        }

        <#
        if (-Not (Assert-ParentPath $Path 'src')) {
            Exit-ProjectError "Path[$Path] does not match the correct parent directory"
        }
        #>

        $Path
    }
}
<#
function Protect-RootPath {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline,
            Mandatory
        )][string]$Path
    )

    process {
        Write-FunctionVerbose
        $Path = Resolve-Path $Path
        $Root = [System.IO.Path]::GetPathRoot($Path)
        $Test = $Path -eq $Root
        Write-Verbose "Path is Root: $Test"
        #'Path', 'Root', 'Test' | Get-Variable | Select-Object -Property * | Write-Verbose
        Write-VariableVerbose @{ Path = $Path; Root = $Root; Test = $Test }

        if ($Test) {
            #Throw "Path[$Path] is a system root directory which can lead to unwanted system changes"
            Write-Host "Path[$Path] is a system root directory which can lead to unwanted system changes"
            Exit 1
        } else {
            Write-Host "Path[$Path] is valid"
            $Path
        }
    }
}
#>
function Initialize-Directory {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )][string]$Path = $ProjectRoot
    )

    process {
        Write-FunctionVerbose

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
            Position = 0,
            ValueFromPipeline
        )][string]$Path = $ProjectRoot,
        [switch]$WhatIf
    )

    process {
        Write-FunctionVerbose

        if (Test-Path $Path) {
            Get-ChildItem $Path | Remove-Item -Recurse -WhatIf:$WhatIf
        }
    }
}
function Request-App {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )][string]$Parent = $ProjectRoot,
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
        Write-FunctionVerbose
        $Name = [System.IO.Path]::GetFileName($Uri)
        $Path = "$Parent\$Name"
        $RemainingRetry = $Retry
        #$WebClient = New-Object System.Net.WebClient

        while ($RemainingRetry -gt 0) {
            try {
                Write-Host "Downloading[$($App.Uri)]:`n`nPlease wait...`n"
                #$WebClient.DownloadFile($Uri, $Path)
                #Invoke-RestMethod -ContentType "application/octet-stream" -Uri $Uri -OutFile $Path | Out-Null
                #Invoke-WebRequest -Uri $Uri -OutFile $Path | Out-Null
                #Start-BitsTransfer -Source $Uri -Destination $Path -Priority Foreground
                curl.exe -o $Path $Uri
                Write-Host "curl.exe finished"
                break
            } catch {
                Write-Host "Error: $_"
                Start-Sleep -Milliseconds $Delay
            }
        }

        $App.Path = $Path
        Write-VariableVerbose @{ Name = $Name; Path = $Path; RemainingRetry = $RemainingRetry }
        $App.Pass.Invoke()
    }
}
function Export-Archive {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipelineByPropertyName
        )][string]$Path = $ProjectRoot,
        [Parameter(
            ValueFromPipeline
        )][PSCustomObject]$App
    )

    begin {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
    }

    process {
        Write-FunctionVerbose
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
        Write-VariableVerbose @{ Parent = $Parent; Name = $Name; Extract = $Extract }
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
            ValueFromPipelineByPropertyName
        )][string]$Filter,
        [Parameter(
            ValueFromPipelineByPropertyName
        )][string]$Path = $ProjectRoot,
        [Parameter(
            ValueFromPipeline
        )][PSCustomObject]$App
    )

    process {
        Write-FunctionVerbose
        Get-ChildItem $Path $Filter -Recurse | ForEach-Object {
            $Source = $PSItem.FullName
            Write-Host "Moving directory from Source to Destination:`n[$Source]`n[$Destination]"
            Move-Item -Path $Source $Destination -Force
        }
        Write-VariableVerbose @{ Destination = $Destination }
        $Destination
    }
}
function Get-EnvPath {
    [CmdletBinding()]
    param()

    process {
        Write-FunctionVerbose
        $EnvPathSystem = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
        $EnvPathUser = [System.Environment]::GetEnvironmentVariable('Path', 'User')
        $EnvPath = "$EnvPathSystem;$EnvPathUser"
        Write-VariableVerbose @{ EnvPathSystem = $EnvPathSystem; EnvPathUser = $EnvPathUser; EnvPath = $EnvPath }
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
        Write-FunctionVerbose
        $EnvPath = Get-EnvPath

        $Contain = $EnvPath -like "*$Entry*"
        $Append = "$Entry;"

        if (-Not $Contain) {
            $EnvPathUser = [System.Environment]::GetEnvironmentVariable('Path', 'User') + $Append
            [System.Environment]::SetEnvironmentVariable('Path', $EnvPathUser, 'User')
            $Env:Path = Get-EnvPath
            Write-Host "Added Path[$Entry] to user environment variables"
        }
    }
}
function Test-AppExist {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipelineByPropertyName
        )][string]$Name
    )

    process {
        Write-FunctionVerbose
        $Exist = [bool](Get-Command $Name -CommandType Application -ErrorAction Ignore)
        Write-VariableVerbose @{ Missing = $Missing }
        $Exist
    }
}
function Test-AnyAppMissing {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipelineByPropertyName
        )][string]$Name
    )

    begin {
        $Exists = [System.Collections.Generic.List[bool]]::new()
    }

    process {
        $Exists.Add((Test-AppExist $Name))
    }

    end {
        $Exists -contains $false
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
        Write-FunctionVerbose
        $UserSelectDirectory = New-Object System.Windows.Forms.FolderBrowserDialog
        $UserSelectDirectory.SelectedPath = $Path
        $UserSelectDirectory.ShowNewFolderButton = $true
        $Prompt = 'Opening [System.Windows.Forms.FolderBrowserDialog] for selecting download path'
        Write-Host $Prompt
        $UserSelectDirectory.Description = $Prompt
        $Result = $UserSelectDirectory.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK

        if ($Result) {
            $Path = $UserSelectDirectory.SelectedPath
            Write-Host "User selected download Path[$Path]"
        } else {
            Write-Host "Invalid path selected. Using default Path[$Path]"
        }

        Write-VariableVerbose @{ Result = $Result; Path = $Path }
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