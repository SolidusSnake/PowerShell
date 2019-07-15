

$header = @"
 __   __  _______  _______  _______  _______  _______ 
|  |_|  ||       ||   _   ||       ||       ||       |
|       ||       ||  |_|  ||    ___||    ___||    ___|
|       ||       ||       ||   |___ |   |___ |   |___ 
|       ||      _||       ||    ___||    ___||    ___|
| ||_|| ||     |_ |   _   ||   |    |   |___ |   |___ 
|_|   |_||_______||__| |__||___|    |_______||_______|
`n`n
"@



$mcafee_menu = @{
	1 = @{
		'name' = 'Disable OAS';
		'file' = 'McAfee/dOAS.ps1';
	};
	2 = @{
		'name' = 'Enable OAS'
		'file' = 'McAfee/eOAS.ps1'
	};
	3 = @{
		'name' = 'Collect and Send Props'
		'file' = 'McAfee/CollProp.ps1'
	};
	4 = @{
		'name' = 'Version Checker'
		'file' = 'McAfee/MFEV.ps1'
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