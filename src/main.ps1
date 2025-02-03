Write-Host "Script Path[$PSCommandPath]"
Set-Location "$PSScriptRoot\.."
. .\src\initialize.ps1
Initialize-ProjectApplication
$Destination = Show-SelectDirectory
Write-Host "Downloading into Destination[$Destination]"

while ($true) {
    $UserInput = Read-Host 'Youtube URL'
    & yt-dlp -x --audio-format mp3 --audio-quality 0 -o "$Destination\%(title)s.%(ext)s" $UserInput
}