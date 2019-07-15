

$header = @"
 _______  __   __  _______  __    _  _______  _______ 
|       ||  | |  ||       ||  |  | ||       ||       |
|    ___||  |_|  ||    ___||   |_| ||_     _||  _____|
|   |___ |       ||   |___ |       |  |   |  | |_____ 
|    ___||       ||    ___||  _    |  |   |  |_____  |
|   |___  |     | |   |___ | | |   |  |   |   _____| |
|_______|  |___|  |_______||_|  |__|  |___|  |_______|
`n`n
"@

$event_menu = @{
	0 = @{
		'name' = 'Last 100 Errors';
		'file' = 'EventLog/listerrors.ps1';
	};
	1 = @{
		'name' = 'Last 100 Warnings';
		'file' = 'EventLog/listwarnings.ps1';
	};
	2 = @{
		'name' = 'Search by time genesis';
		'file' = 'EventLog/genesis.ps1';
	};
	3 = @{
		'name' = 'List Account Logons';
		'file' = 'EventLog/logons.ps1';
	};
	4 = @{
		'name' = 'List Server Reboots';
		'file' = 'EventLog/listreboots.ps1';
	};
	99 = @{
		'name' = 'Exit';
		'file' = 'exit.ps1';
	}
}

function get-earliesteventdate {

	param (
		[string]$logname = 'system'
	)
	
	Return (get-winevent -LogName $logname -Oldest -MaxEvents 1)[0].TimeCreated.ToString()

}



while (1) {
	cls
	write-host $header
	$event_menu.getenumerator() | sort key | % { write-host $($_.key , "`t" , $_.value.name) }
	Write-Host $("`n" + 'Earliest System event available: ' + (get-earliesteventdate 'system'))
	Write-Host $('Earliest Security event available: ' + (get-earliesteventdate 'security'))
	Write-Host $('Earliest Application event available: ' + (get-earliesteventdate 'application'))
	$sel = read-host "`nMake a selection..."
	If ($sel -ne "99") {
		write-host $('choosing: ' +  $event_menu[[int]$sel].file);
		#start-process -wait -nonewwindow -filepath $($env:systemroot + '\system32\WindowsPowershell\v1.0\powershell.exe') -argumentlist $('-file ./scripts/' + $event_menu[[int]$sel].file) 
		. $('./scripts/' + $event_menu[[int]$sel].file)
	} else {
		exit
	}
}