

$header = @"
 _______  ______    _______  ______   ___   _______  _______ 
|       ||    _ |  |       ||      | |   | |       ||       |
|       ||   | ||  |    ___||  _    ||   | |_     _||  _____|
|       ||   |_||_ |   |___ | | |   ||   |   |   |  | |_____ 
|      _||    __  ||    ___|| |_|   ||   |   |   |  |_____  |
|     |_ |   |  | ||   |___ |       ||   |   |   |   _____| |
|_______||___|  |_||_______||______| |___|   |___|  |_______|
`n`n
"@

cls
write-host -Foregroundcolor Green $header

$credStr = 'I would like to thank the community at large for scraping together the scripts needed for this tool.'

($credStr -split '') | % { 
	Write-Host -Foregroundcolor Green -NoNewLine $_
	Start-sleep -milliseconds 75
}