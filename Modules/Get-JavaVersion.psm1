Function Get-JavaVersion
{
	<#
	.SYNOPSIS
		Gets java.exe version from predefined locations for x86 and x64.
		
	.DESCRIPTION
		This function was created to check for installed instances of Java
		and, if installed, return the version information. This checks for
		java.exe in the default installed locations listed below:
	
		%ProgramFiles%\java\jre6\bin\
		%ProgramFiles%\java\jre7\bin\
		%ProgramFiles(x86)%\java\jre6\bin\
		%ProgramFiles(x86)%\java\jre7\bin\
	
	.PARAMETER ComputerName
		One or more computers to retrieve Java versions from.
		
	.EXAMPLE
		Get-JavaVersion -ComputerName server01
		
		Description
		-----------
		Retrieves installed Java version[s] on computer 'server01'.
	
	.EXAMPLE
		Get-JavaVersion -ComputerName (Get-Content .\computers.txt)
		
		Description
		-----------
		Retrieves installed Java version[s] from all computers listed
		in 'computers.txt'.
	#>

	Param([Parameter(Mandatory = $True,
	ValueFromPipeLine = $False,
	Position = 0)]
	[Alias('')]
	[String[]]$ComputerName = "localhost")
	
	
	PROCESS
	{
		foreach ($computer in $ComputerName)
		{
			IF (Test-Path "\\$computer\c$\Program Files (x86)\java\jre7\bin\java.exe")
			{
				Echo"--FOUND 32Bit JAVA JRE7 on $computer--"
				$jarver = (get-item "\\$computer\c$\Program Files (x86)\java\jre7\bin\java.exe").VersionInfo.ProductVersion
				Echo"32bit Version:" $jarver
			}
			ELSE
			{
				Echo"NO 32Bit Java JRE7 Installed on $computer"
			}
			
			IF (Test-Path "\\$computer\c$\Program Files\java\jre7\bin\java.exe")
			{
				Echo"--FOUND 64Bit JAVA JRE7 on $computer--"
				$jarver = (get-item "\\$computer\c$\Program Files\java\jre7\bin\java.exe").VersionInfo.ProductVersion
				Echo"64bit Version:" $jarver
			}
			ELSE
			{
				Echo"NO 64Bit Java JRE7 Installed on $computer"
			}
			
			IF (Test-Path "\\$computer\c$\Program Files (x86)\java\jre6\bin\java.exe")
			{
				Echo"--FOUND 32Bit JAVA JRE6 on $computer--"
				$jarver = (get-item "\\$computer\c$\Program Files (x86)\java\jre6\bin\java.exe").VersionInfo.ProductVersion
				Echo"32bit Version:" $jarver
			}
			ELSE
			{
				Echo"NO 32Bit Java JRE6 Installed on $computer"
			}
			
			IF (Test-Path "\\$computer\c$\Program Files\java\jre6\bin\java.exe")
			{
				Echo"--FOUND 64Bit JAVA JRE6 on $computer--"
				$jarver = (get-item "\\$computer\c$\Program Files\java\jre6\bin\java.exe").VersionInfo.ProductVersion
				Echo"64bit Version:" $jarver
			}
			ELSE
			{
				Echo"NO 64Bit Java JRE6 Installed on $computer"
			}
		
		## Creates a blank space between returned information for each server; 
		Echo""
		}
	}
}
