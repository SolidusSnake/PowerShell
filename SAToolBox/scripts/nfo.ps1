

$header = @"
 _______  __   __  _______  __    _  _______  _______ 
|       ||  | |  ||       ||  |  | ||       ||       |
|  _____||  |_|  ||  _____||   |_| ||    ___||   _   |
| |_____ |       || |_____ |       ||   |___ |  | |  |
|_____  ||_     _||_____  ||  _    ||    ___||  |_|  |
 _____| |  |   |   _____| || | |   ||   |    |       |
|_______|  |___|  |_______||_|  |__||___|    |_______|
`n`n
"@

cls

write-host $header

. ./scripts/_sharedfunc.ps1

function get-bootdate {
	((Invoke-Expression 'net statistics Workstation') -join "`n") -match 'since (?<date>.*)' | out-null
	Return $matches.date
}

$nfo = @{
	'Computer Name' = ($env:computername);
	'Domain Name' = (Get-WmiObject Win32_ComputerSystem).domain;
	'Last Reboot' = (get-bootdate);
	'IP Addresses' = ((get-ipaddresses | select ipaddress).ipaddress -join ",")
}

$nfo | format-table -autosize

read-host "`n`nDone."