

$header = @"
 _______  _______  __   __ 
|       ||       ||  | |  |
|       ||    _  ||  | |  |
|       ||   |_| ||  |_|  |
|      _||    ___||       |
|     |_ |   |    |       |
|_______||___|    |_______|
`n`n
"@


$cpu_menu = @{
	0 = @{
		'name' = 'Process Watcher';
		'file' = 'CPU/cpu_proc_watcher.ps1';
	};
	99 = @{
		'name' = 'Exit';
		'file' = 'exit.ps1';
	}

}


while (1) {
	cls
	write-host $header
	$cpu_menu.getenumerator() | sort key | % { write-host $($_.key , "`t" , $_.value.name) }
	$sel = read-host "`nMake a selection..."
	If ($sel -ne "99") {
		write-host $('choosing: ' +  $cpu_menu[[int]$sel].file);
		start-process -filepath $($env:systemroot + '\system32\WindowsPowershell\v1.0\powershell.exe') -argumentlist $('-file ./scripts/' + $cpu_menu[[int]$sel].file) 
		#. $('./scripts/' + $cpu_menu[[int]$sel].file)
	} else {
		exit;
	}
}