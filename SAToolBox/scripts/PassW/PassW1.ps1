

$header = @"
 ______    _______  __    _  ______   _______  __   __    _______  _     _ 
|    _ |  |   _   ||  |  | ||      | |       ||  |_|  |  |       || | _ | |
|   | ||  |  |_|  ||   |_| ||  _    ||   _   ||       |  |    _  || || || |
|   |_||_ |       ||       || | |   ||  | |  ||       |  |   |_| ||       |
|    __  ||       ||  _    || |_|   ||  |_|  ||       |  |    ___||       |
|   |  | ||   _   || | |   ||       ||       || ||_|| |  |   |    |   _   |
|___|  |_||__| |__||_|  |__||______| |_______||_|   |_|  |___|    |__| |__|
`n`n
"@



$mcafee_menu = @{
	1 = @{
		'name' = 'Generate 1 Random Password';
		'file' = 'PassW/1Pass.ps1';

	};
	5 = @{
		'name' = 'Generate 5 Random Passwords';
		'file' = 'PassW/5Pass.ps1';

	};
	10 = @{
		'name' = 'Generate 10 Random Passwords';
		'file' = 'PassW/10Pass.ps1';

	};
	99 = @{
		'name' = 'Exit';
		'file' = 'exit.ps1';
	}
}


while (1) {
	cls
	write-host $header
	$mcafee_menu.getenumerator() | sort key | % { write-host $($_.key , "`t" , $_.value.name) }
	$sel = read-host "`nMake a selection..."
#
#
#
#
#
#
#
#
	If ($sel -ne '99') {
		write-host $('choosing: ' +  $mcafee_menu[[int]$sel].file);
		#start-process -wait -nonewwindow -filepath $($env:systemroot + '\system32\WindowsPowershell\v1.0\powershell.exe') -argumentlist $('-file ./scripts/' + $mcafee_menu[[int]$sel].file)
		. $('./scripts/' + $mcafee_menu[[int]$sel].file)
	} else {
		exit
	}
}