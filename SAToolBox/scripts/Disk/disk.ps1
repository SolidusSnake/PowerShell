

$header = @"
 ______   ___   _______  ___   _ 
|      | |   | |       ||   | | |
|  _    ||   | |  _____||   |_| |
| | |   ||   | | |_____ |      _|
| |_|   ||   | |_____  ||     |_ 
|       ||   |  _____| ||    _  |
|______| |___| |_______||___| |_|
`n`n
"@


$disk_menu = @{
	0 = @{
		'name' = 'Directory Sizes';
		'file' = 'Disk/dir.ps1';
	};
    1 = @{
		'name' = 'Clean C: ';
		'file' = 'Disk/cleanC.ps1';
	};
	99 = @{
		'name' = 'Exit';
		'file' = 'exit.ps1';
	}

}


while (1) {
	cls
	write-host $header
	$disk_menu.getenumerator() | sort key | % { write-host $($_.key , "`t" , $_.value.name) }
	$sel = read-host "`nMake a selection..."
	If ($sel -ne "99") {
		write-host $('choosing: ' +  $disk_menu[[int]$sel].file);
		#start-process -wait -nonewwindow -filepath $($env:systemroot + '\system32\WindowsPowershell\v1.0\powershell.exe') -argumentlist $('-file ./scripts/' + $disk_menu[[int]$sel].file) 
		. $('./scripts/' + $disk_menu[[int]$sel].file)
	} else {
		exit;
	}
}