'Scriptfile[{0}]' -f $PSCommandPath | Out-Host
$Path = '{0}\Downloads\*' -f $Env:USERPROFILE
$Ext = Get-MediaExtension | ForEach-Object { "*.$_" }
Get-ChildItem $Path -Include $Ext | Remove-Item -WhatIf