param(
    $ProjectRoot = $(throw 'ProjectRoot is required')
)

try {
    Get-NetAdapter | Select-Object Name, InterfaceDescription, LinkSpeed | Out-Host
    $ProjectName = Split-Path $ProjectRoot -Leaf
    Set-Location $ProjectRoot
    Set-Variable ErrorActionPreference Stop
    Set-Variable ProgressPreference SilentlyContinue
    Set-Variable VerbosePreference SilentlyContinue
    . .\src\functions $ProjectRoot
    . .\src\initialize $ProjectRoot
    Initialize-ProjectApplication
    $Destination = Show-SelectDirectory
    $Config = @('-x', '--audio-format', 'mp3', '--audio-quality', '0')
    $Downloads = [System.Collections.Generic.List[string]]::new()

    while ($true) {
        #Clear-Host
        Write-Host "Project[$ProjectName]`n"
        $Downloads | Show-Downloads
        $URL = Read-Host 'Youtube URL'
        & yt-dlp @Config -o "$Destination\%(title)s.%(ext)s" $URL
        $Downloads.Add($URL)
        # Add metadata
    }
}
catch {
    Write-Host "`nCaught error in [$PSCommandPath]:`n`n$_`n" -ForegroundColor DarkYellow
    Pause
    Exit 1
}