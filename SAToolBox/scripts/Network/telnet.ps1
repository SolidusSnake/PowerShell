

$header = @"
 _______  _______  _______  _______  ___      __    _  _______  _______ 
|       ||       ||       ||       ||   |    |  |  | ||       ||       |
|    _  ||  _____||_     _||    ___||   |    |   |_| ||    ___||_     _|
|   |_| || |_____   |   |  |   |___ |   |    |       ||   |___   |   |  
|    ___||_____  |  |   |  |    ___||   |___ |  _    ||    ___|  |   |  
|   |     _____| |  |   |  |   |___ |       || | |   ||   |___   |   |  
|___|    |_______|  |___|  |_______||_______||_|  |__||_______|  |___|
`n`n
"@

cls

write-host $header

function pstelnet {
	param (
		$port = '80',
		$server = '158.15.134.132',
		$clientType = 'TCP'
	)

	try {       
		If ($clientType -eq 'TCP') {
			$null = New-Object System.Net.Sockets.TCPClient -ArgumentList $server,$port
		} else {
			$null = New-Object System.Net.Sockets.UDPClient -ArgumentList $server,$port
		}
			
		$props = @{
			Server = $server
			PortOpen = 'Yes'
		}
	} catch {
		$props = @{
			Server = $server
			PortOpen = 'No'
		}
	}

	Return $props
}

while (1) {
	$dest = read-host "Enter your destination server or IP [Enter Q to quit]"
	$destport = read-host "Enter the destination port [Enter Q to quit]"

	If ($dest -eq "q" -or $destport -eq "q") {
		exit
	} else {
		write-host "the result of your query is:`n"
		(pstelnet -server $dest -port $destport).portOpen
	}
}