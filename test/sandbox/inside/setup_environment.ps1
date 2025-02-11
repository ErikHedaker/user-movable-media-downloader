'Script File[{0}]' -f
$PSCommandPath | Out-Host
$Assert = {
    param([string]$UserActive, [string]$UserAllow = 'WDAGUtilityAccount')
    if ($UserActive -ne $UserAllow) {
        "`nInvalid [User] environment. Script expects Windows Sandbox [User]:`n[{0}]`n[{1}]`n" -f
        $UserActive, $UserPermitted | Write-Host -ForegroundColor DarkYellow
        Pause
        [System.Environment]::Exit(1)
    }
}
& $Assert -UserActive $Env:USERNAME
.\test\sandbox\inside\remove_user_admin.ps1 $Assert