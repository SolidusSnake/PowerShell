

$menu = @{
	0 = @{
		'name' = 'System Info';
		'file' = 'nfo.ps1';
	};
	1 = @{
		'name' = 'Networking';
		'file' = 'Network/net.ps1';
	};
	2 = @{
		'name' ='Memory';
		'file' = 'mem.ps1';
	};
	3 = @{
		'name' = 'CPU';
		'file' = 'Cpu/cpu.ps1';
	};
	4 = @{
		'name' = 'Disk';
		'file' = 'Disk/disk.ps1';
	};
	5 = @{
		'name' = 'Event Log';
		'file' = 'EventLog/events.ps1';
	};
	6 = @{
		'name' = 'Updates';
		'file' = 'Updates/ud.ps1';
	};
    	7 = @{
		'name' = 'McAfee';
		'file' = 'McAfee/mcafee.ps1';
	};
	8 = @{
		'name' = 'Password Generator';
		'file' = 'PassW/Passw1.ps1'
	};
	98 = @{
		'name' = 'Credits';
		'file' = '_credz.ps1';
	};
	99 = @{
		'name' = 'Exit';
		'file' = 'exit.ps1';
	};
}



while (1) {
	cls
	write-host $main_header
	$menu.getenumerator() | sort key | % { write-host $($_.key , "`t" , $_.value.name) }
	$sel = read-host "`nMake a selection..."
	If ($sel -eq 99) {
		exit
	} else {
		write-host $('choosing: ' + $menu[[int]$sel].name);
		#start-process -wait -nonewwindow -filepath $($env:systemroot + '\system32\WindowsPowershell\v1.0\powershell.exe') -argumentlist $('-file ./scripts/' + $menu[[int]$sel].file) 
		. $('./scripts/' + $menu[[int]$sel].file)
	}
}