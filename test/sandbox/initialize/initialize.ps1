function New-SandboxContent {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )][string]$SharedInput,
        [Parameter(
            Position = 1
        )][string]$SharedOutput,
        [Parameter(
            Position = 2
        )][string]$Command
    )

    process {
        Write-Host "$($MyInvocation.MyCommand.Name) In[$SharedInput] Out[$SharedOutput]"
        @"
<Configuration>
    <MappedFolders>
        <MappedFolder>
            <HostFolder>$SharedInput</HostFolder>
            <SandboxFolder>$SharedOutput</SandboxFolder>
            <ReadOnly>true</ReadOnly>
        </MappedFolder>
    </MappedFolders>
    <LogonCommand>
        <Command>$Command</Command>
    </LogonCommand>
</Configuration>
"@
    }
}

function Export-SandboxFile {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )][string]$Path,
        [Parameter(
            ValueFromPipeline
        )][string]$Content
    )

    process {
        Write-Host "$($MyInvocation.MyCommand.Name) Path[$Path]"

        if (Test-Path $Path) {
            Remove-Item $Path
        }

        New-Item $Path -ItemType File | Out-Null
        $Content | Out-File -FilePath $Path
        $Path
    }
}

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

Write-Host "Script Path[$PSCommandPath]"
$Process = 'WindowsSandboxRemoteSession*'
Get-Process -Name $Process | Stop-Process -Force
Write-Host "Stop-Process Name[$Process]"
$SourcePath = (Get-Location).Path
$ProjectName = Split-Path $SourcePath -Leaf
$SharedInput = "$env:USERPROFILE\Sandbox\$ProjectName" + '_copy'
$SharedOutput = "C:\Users\WDAGUtilityAccount\Downloads\$ProjectName"
$Command = $CommandTest[0]
$SandboxFile = New-SandboxContent $SharedInput $SharedOutput $Command |
    Export-SandboxFile 'test\sandbox\initialize\sandbox.wsb'
& robocopy $SourcePath $SharedInput /MIR /XD .git docs /XF README.md
& "$SharedInput\$SandboxFile"