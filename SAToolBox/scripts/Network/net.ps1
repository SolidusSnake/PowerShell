

$header = @"
 __    _  _______  _______  _     _  _______  ______    ___   _ 
|  |  | ||       ||       || | _ | ||       ||    _ |  |   | | |
|   |_| ||    ___||_     _|| || || ||   _   ||   | ||  |   |_| |
|       ||   |___   |   |  |       ||  | |  ||   |_||_ |      _|
|  _    ||    ___|  |   |  |       ||  |_|  ||    __  ||     |_ 
| | |   ||   |___   |   |  |   _   ||       ||   |  | ||    _  |
|_|  |__||_______|  |___|  |__| |__||_______||___|  |_||___| |_|
`n`n
"@

$net_menu = @{
	0 = @{
		'name' = 'Ping Gateway';
		'file' = 'Network/ping_gw.ps1';
	};
	1 = @{
		'name' = 'PSTelnet';
		'file' = 'Network/telnet.ps1';
	};
	99 = @{
		'name' = 'Exit';
		'file' = 'exit.ps1';
	}
}

while (1) {
	cls
	write-host $header
	$net_menu.getenumerator() | sort key | % { write-host $($_.key , "`t" , $_.value.name) }
	$sel = read-host "`nMake a selection..."
	If ($sel -ne "99") {
		write-host $('choosing: ' +  $net_menu[[int]$sel].file);
		#start-process -wait -nonewwindow -filepath $($env:systemroot + '\system32\WindowsPowershell\v1.0\powershell.exe') -argumentlist $('-file ./scripts/' + $net_menu[[int]$sel].file) 
		. $('./scripts/' + $net_menu[[int]$sel].file)
	} else {
		exit
	}
}