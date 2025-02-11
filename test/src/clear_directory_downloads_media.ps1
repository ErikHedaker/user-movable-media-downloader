Write-Host "Script File[$PSCommandPath]"
$Extensions = Get-MediaExtension | ForEach-Object { "*.$_" }
Get-ChildItem -Path "$Env:USERPROFILE\Downloads\*" -Include $Extensions | Remove-Item -WhatIf