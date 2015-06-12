##--------------------------------------------------------------------------
##  FUNCTION.......:  Get-Uptime
##  PURPOSE........:  Calculates uptime for the specified computer.
##  REQUIREMENTS...:  
##  NOTES..........:  
##--------------------------------------------------------------------------
Function Get-Uptime {
    ##----------------------------------------------------------------------
    ##  Comment Based Help for this function.
    ##----------------------------------------------------------------------
    
    <#
    .SYNOPSIS
     Calculates uptime for the specified computer.
    .DESCRIPTION
     This function uses the Win32_OperatingSystem class to retrieve the
     LastBootUpTime, and calculate uptime based on the local system time.
    .PARAMETER ComputerName
     The name or IP address of the computer to calculate uptime for.
         
    .EXAMPLE
     C:\PS>Get-Uptime DC01
     
     Displays uptime for the computer named "DC01"
         
    .NOTES
     NAME......:  Get-Uptime
     AUTHOR....:  Joe Glessner
     LAST EDIT.:  15MAY12
     CREATED...:  11APR11
    .LINK
     http://joeit.wordpress.com/
    #>
        
    ##----------------------------------------------------------------------
    ##  Function Parameters.
    ##----------------------------------------------------------------------
    Param([Parameter(Mandatory = $True,
        ValueFromPipeLine = $False,
        Position = 0)]
        [Alias('')]
        [String[]]$ComputerName = "localhost"
  	##---[String]$ComputerName = "localhost"---##Single computer
    )#END: Param
	
	##PROCESS ADD
	PROCESS
	{
		foreach ($Computer in $ComputerName)
		{	
		$LastBoot = (Get-WmiObject -Class Win32_OperatingSystem -computername $Computer).LastBootUpTime
		$sysuptime = (Get-Date) – [System.Management.ManagementDateTimeconverter]::ToDateTime($LastBoot)
		Write-Host -foregroundcolor cyan "($Computer) System uptime is:"$sysuptime.days"days"$sysuptime.hours"hours"$sysuptime.minutes"minutes"$sysuptime.seconds"seconds"
		}
	}
}#End Function Get-Uptime
