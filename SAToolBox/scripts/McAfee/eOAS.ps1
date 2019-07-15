<#
Disable OAP automatically. Repeatedly disables OAP at a specified interval. 
#>

& 'C:\Program Files (x86)\McAfee\VirusScan Enterprise\mcadmin.exe' /enableoas

# If running in the console, wait for input before closing.
		if ($Host.Name -eq "ConsoleHost")
	{
    		

	
		Write-Host "`n        OAS has been enabled..." -foregroundcolor magenta -nonewline; write-host "       Press enter to exit"
    		$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}


read-host "`n`n Press Enter to exit......"