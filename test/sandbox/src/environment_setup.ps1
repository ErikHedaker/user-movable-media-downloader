param([string]$ProjectRoot = $(throw 'ProjectRoot script parameter is required'))
function Assert-SandboxEnvironment {
    [CmdletBinding()]
    param()

    begin {
        $UserCurrent = $Env:USERNAME
        $UserSandbox = 'WDAGUtilityAccount'
    }

    process {
        if ($UserCurrent -ne $UserSandbox) {
            "`n[User] environment is invalid. " +
            "Script is expecting Windows Sandbox [User]:`n[{0}]`n[{1}]`n" -f
            $UserCurrent, $UserSandbox | Write-Host -ForegroundColor DarkYellow
            Pause
            [Environment]::Exit(1)
        }
    }
}

'Scriptfile[{0}]' -f $PSCommandPath | Out-Host
Assert-SandboxEnvironment
$ProjectName = Split-Path $ProjectRoot -Leaf
$Destination = '{0}\{1}' -f $Env:USERPROFILE, $ProjectName
& robocopy $ProjectRoot $Destination /E
Set-Location $Destination
'Moved CWD[{0}]' -f (Get-Location) | Out-Host
.\test\sandbox\src\environment_remove_admin.ps1
.\start.cmd