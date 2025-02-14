if ($null -eq $MyInvocation.ScriptName) {
    'Scriptfile[{0}] should not be executed directly' -f $PSCommandPath | Out-Host
    exit
}

'Scriptfile[{0}]' -f $PSCommandPath | Out-Host
Assert-SandboxEnvironment