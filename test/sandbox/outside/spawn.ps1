param($ProjectRoot = $(throw 'ProjectRoot is required'))
function New-SandboxContent {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$SharedInput,
        [Parameter(
            Mandatory,
            Position = 1
        )][string]$SharedOutput,
        [Parameter(
            Mandatory,
            Position = 2
        )][string]$Command
    )

    process {
        "<Configuration>`n" +
        "    <MappedFolders>`n" +
        "        <MappedFolder>`n" +
        "            <HostFolder>$SharedInput</HostFolder>`n" +
        "            <SandboxFolder>$SharedOutput</SandboxFolder>`n" +
        "            <ReadOnly>true</ReadOnly>`n" +
        "        </MappedFolder>`n" +
        "    </MappedFolders>`n" +
        "    <LogonCommand>`n" +
        "        <Command>$Command</Command>`n" +
        "    </LogonCommand>`n" +
        "</Configuration>`n"
    }
}
function Export-SandboxFile {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )][string]$Path,
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )][string]$Content
    )

    process {
        $Parent = Split-Path $Path -Parent

        if (-not (Test-Path $Parent)) {
            New-Item $Parent -ItemType Directory | Out-Null
            'Created Directory[{0}]' -f $Parent | Out-Host
        }

        if (Test-Path $Path) {
            Remove-Item $Path
            'Removed File[{0}]' -f $Path | Out-Host
        }

        $Content | Out-File -FilePath $Path
        'Created File[{0}]' -f $Path | Out-Host
        $Path
    }
}

try {
    Set-Location $ProjectRoot
    Set-Variable ErrorActionPreference Stop
    Set-Variable ProgressPreference SilentlyContinue
    'Script File[{0}]' -f $PSCommandPath | Out-Host
    Get-Process -Name 'WindowsSandboxRemoteSession*' |
        Stop-Process -Force -PassThru |
            ForEach-Object { 'Stopped Process[{0}]' -f $_.ProcessName } |
                Out-Host
    $ProjectName = Split-Path $ProjectRoot -Leaf
    $SharedInput = "$env:USERPROFILE\Sandbox\$ProjectName" + '_copy'
    $SharedOutput = "C:\Users\WDAGUtilityAccount\Downloads\$ProjectName"

    $CommandTest = $(
        "explorer $SharedOutput\test\sandbox",
        "start $SharedOutput\tests\sandbox\env_start.cmd",
        "ping 127.0.0.1 -n 2 &amp; explorer $SharedOutput\tests\sandbox",
        "ping -n 3 127.0.0.1 &gt; nul &amp; explorer $SharedOutput\tests\sandbox",
        "timeout 5 && $SharedOutput\tests\sandbox\env_start.cmd",
        "powershell.exe -ExecutionPolicy Bypass -Command '& { explorer $SharedOutput\tests\sandbox }'",
        "powershell.exe -ExecutionPolicy Bypass -Command 'Invoke-Command -ScriptBlock { explorer C:\Users\WDAGUtilityAccount\Sandbox\AutoUserSetup\tests\sandbox }'",
        "powershell -ExecutionPolicy Bypass $SharedOutput\tests\sandbox\env_start.cmd"
    )

    $Command = $CommandTest[0]
    $SandboxFile = New-SandboxContent $SharedInput $SharedOutput $Command |
        Export-SandboxFile 'test\sandbox\out\sandbox.wsb'
    & robocopy $ProjectRoot $SharedInput /MIR /XD .git docs /XF README.md
    & "$SharedInput\$SandboxFile"
} catch {
    "`nError:`n`n$_`n" |
        Write-Host -ForegroundColor DarkYellow
    Pause
    Exit 1
}