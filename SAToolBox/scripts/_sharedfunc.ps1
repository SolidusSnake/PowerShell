

function get-IPaddresses {
	write-verbose $('Probing the registry for IP addresses...')
	return (Get-Childitem Registry::HKLM\System\CurrentControlSet\Services\tcpip\parameters\interfaces | Foreach-Object { Get-ItemProperty Registry::$_ } | ? { $_.IPAddress -ne $null })
}