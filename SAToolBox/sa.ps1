#Requires -Version 2.0



# font name is 'modular' for ascii titles

If ($MyInvocation.MyCommand.Path -ne $null) {
	Set-Location (Split-Path $MyInvocation.MyCommand.Path)
}

$main_header = @"
 _______  _______    _______  _______  _______  ___      _______ 
|       ||   _   |  |       ||       ||       ||   |    |       |
|  _____||  |_|  |  |_     _||   _   ||   _   ||   |    |  _____|
| |_____ |       |    |   |  |  | |  ||  | |  ||   |    | |_____ 
|_____  ||       |    |   |  |  |_|  ||  |_|  ||   |___ |_____  |
 _____| ||   _   |    |   |  |       ||       ||       | _____| |
|_______||__| |__|    |___|  |_______||_______||_______||_______|
`t`tSystem Administrator Toolbox v0.1`n
"@

clear-host
write-host $main_header

. .\scripts\_menu.ps1