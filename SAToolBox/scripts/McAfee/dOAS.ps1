<#
Disable OAP automatically. Repeatedly disables OAP at a specified interval.
edited on: 4Nov2018 
#>
$DisableOAP = {
While ($true) {
 & 'C:\Program Files (x86)\McAfee\VirusScan Enterprise\mcadmin.exe' /disableoas
Sleep -seconds (2*60)
	}
}

Start-Job -scriptblock $disableoap

# If running in the console, wait for input before closing.
		if ($Host.Name -eq "ConsoleHost")
	{
    		

		Write-Host "`n        Leave this window open to disable OAP automatically every 2 min...        `r" -foregroundcolor green
		Write-Host "`n        OAP can be re-enabled from the McAfee Menu...        `r" -foregroundcolor magenta
		Write-Host "`n        press enter to stop the cycle of auto-disabling OAS...        `r" -foregroundcolor green
    		$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}


read-host "`n`npress enter to exit........"