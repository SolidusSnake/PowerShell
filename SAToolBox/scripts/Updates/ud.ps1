

$header = @"
 __   __  _______  ______   _______  _______  _______  _______ 
|  | |  ||       ||      | |   _   ||       ||       ||       |
|  | |  ||    _  ||  _    ||  |_|  ||_     _||    ___||  _____|
|  |_|  ||   |_| || | |   ||       |  |   |  |   |___ | |_____ 
|       ||    ___|| |_|   ||       |  |   |  |    ___||_____  |
|       ||   |    |       ||   _   |  |   |  |   |___  _____| |
|_______||___|    |______| |__| |__|  |___|  |_______||_______|
`n`n
"@

$update_menu = @{
	0 = @{
		'name' = 'List .NET updates';
		'file' = 'Updates/dotnet_ud.ps1';
	};
	1 = @{
		'name' = 'Search Windows updates';
		'file' = 'Updates/win_ud.ps1';
	};
	99 = @{
		'name' = 'Exit';
		'file' = 'exit.ps1';
	}
}


while (1) {
	cls
	write-host $header
	$update_menu.getenumerator() | sort key | % { write-host $($_.key , "`t" , $_.value.name) }
	$sel = read-host "`nMake a selection..."
	If ($sel -ne "99") {
		write-host $('choosing: ' +  $update_menu[[int]$sel].file);
		#start-process -wait -nonewwindow -filepath $($env:systemroot + '\system32\WindowsPowershell\v1.0\powershell.exe') -argumentlist $('-file ./scripts/' + $update_menu[[int]$sel].file) 
		. $('./scripts/' + $update_menu[[int]$sel].file)
	} else {
		exit
	}
}