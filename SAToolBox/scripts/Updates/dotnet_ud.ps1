

$header = @"
 ______   _______  _______  __    _  _______  _______    __   __  ______  
|      | |       ||       ||  |  | ||       ||       |  |  | |  ||      | 
|  _    ||   _   ||_     _||   |_| ||    ___||_     _|  |  | |  ||  _    |
| | |   ||  | |  |  |   |  |       ||   |___   |   |    |  |_|  || | |   |
| |_|   ||  |_|  |  |   |  |  _    ||    ___|  |   |    |       || |_|   |
|       ||       |  |   |  | | |   ||   |___   |   |    |       ||       |
|______| |_______|  |___|  |_|  |__||_______|  |___|    |_______||______|
`n`n
"@

cls
write-host $header

write-host "See below for a list of .NET updates:`n`n"

$pschilds = @()
$updates = get-childitem -recurse -path "registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Updates"

$updates.getEnumerator() | % {
	$pschilds += $_.pschildname
}

$pschilds

read-host "`n`nDone"