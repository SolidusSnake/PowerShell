
function test-ping {
	param (
		$IP = $NULL
	)

	$pingOut = Invoke-Expression $($env:systemroot + '\system32\ping.exe ' + $IP + ' -l 32 -n 4')

	If ($pingOut -match [regex]"\(0\%\ loss\)") {
		Return $True
	} else {
		Return $False
	}	
}

function test-gateway {
	$defaultGateway = (Get-IPAddresses | Where-Object { $_.DefaultGateway -ne $null } | Select -First 1).DefaultGateway
	If ($defaultGateway) {
		write-host $('Found gateway: ' + $defaultGateway + '...')
		return (Test-Ping $defaultGateway)
	} else {
		write-host $("A default gateway could not be found...")
		return "Default gateway was not found"
	}
}

. ./scripts/_sharedfunc.ps1

$header = @"
 _______  ___   __    _  _______    _______  _     _ 
|       ||   | |  |  | ||       |  |       || | _ | |
|    _  ||   | |   |_| ||    ___|  |    ___|| || || |
|   |_| ||   | |       ||   | __   |   | __ |       |
|    ___||   | |  _    ||   ||  |  |   ||  ||       |
|   |    |   | | | |   ||   |_| |  |   |_| ||   _   |
|___|    |___| |_|  |__||_______|  |_______||__| |__|
`n`n
"@

cls
write-host $header

test-gateway

Read-Host "Done..."