

cls

Write-Host "List of remote logons available in Security event log:`n`n"

((get-winevent -FilterHashtable @{logname='security';id='4624'}) | ? { $_.message -match "logon type.*(10|11)" } | select message,timecreated) | % { 

	$gentime = $_.TimeCreated
	$acctname = (($_.message -split "`n") | select-string -pattern "account name")[1]

	Write-Host $("$acctname on $gentime")

}

Read-Host "Done."