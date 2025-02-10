Write-Host "Script[$PSCommandPath]"
$ExtVideo = @('mp4', 'mov', 'webm', 'flv')
$ExtAudio = @('m4a', 'aac', 'mp3', 'ogg', 'opus', 'webm')
$Include = $ExtVideo + $ExtAudio | ForEach-Object { "*.$_" }
Get-ChildItem -Path "$Env:USERPROFILE\Downloads\*" -Include $Include | Remove-Item -WhatIf