param([scriptblock]$Assert = $(throw 'Assert parameter is required'))
'Script File[{0}]' -f
$PSCommandPath | Out-Host
& $Assert -UserActive $Env:USERNAME