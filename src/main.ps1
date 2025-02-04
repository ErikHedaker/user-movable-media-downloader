param(
    $ProjectRoot = $(throw 'ProjectRoot is required')
)

$ProjectName = Split-Path $ProjectRoot -Leaf
Set-Location $ProjectRoot
Set-Variable ErrorActionPreference Stop
Set-Variable ProgressPreference SilentlyContinue
Set-Variable VerbosePreference SilentlyContinue
. .\src\initialize.ps1 $ProjectRoot
Initialize-ProjectApplication
$Destination = Show-SelectDirectory
$Config = @('-x', '--audio-format', 'mp3', '--audio-quality', '0', '-o', "$Destination\%(title)s.%(ext)s")
$Downloads = [System.Collections.Generic.List[string]]::new()

while ($true) {
    Clear-Host
    Write-Host "Project[$ProjectName]`n"
    $Downloads | Show-Downloads
    $URL = Read-Host 'Youtube URL'
    & yt-dlp @Config $URL
    $Downloads.Add($URL)
    # Add metadata
}