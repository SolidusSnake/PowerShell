

$header = @"
 _     _  ___   __    _    __   __  ______  
| | _ | ||   | |  |  | |  |  | |  ||      | 
| || || ||   | |   |_| |  |  | |  ||  _    |
|       ||   | |       |  |  |_|  || | |   |
|       ||   | |  _    |  |       || |_|   |
|   _   ||   | | | |   |  |       ||       |
|__| |__||___| |_|  |__|  |_______||______|
`n`n
"@

cls
write-host $header

write-host "Gathering updates..."
$upd = get-hotfix

while (1) {
	$updater = Read-Host 'Search for a patch [fields being searched: hotfixid, description, installedby, installedon]'

	If ($updater -ne "q") {
		$upd | ? { $_.hotfixid -match $updater -or $_.description -match $updater -or $_.installedby -match $updater -or $_.installedon -match $updater }
	} else {
		exit
	}

}
