Function Get-PasswordAge
{
	<#
	.SYNOPSIS
		Gets the age of the local users' password.

	.DESCRIPTION
		This command will display a list of all the local users and how old their 
		passwords are. The users that are in good standing will appear green. The 
		users that have passwords that will expire within the next 60 days will 
		appear yellow. The users that have passwords that are expired will appear 
		red.

	.PARAMETER Quiet
		This switch will make this function only show the users that have 
		expired passwords. The users will also be placed in the global variable
		$ExpiredUserPassword. This is so you can easily export the users with 
		expired passwords to a different command for additional action.

	.EXAMPLE
		Get-PasswordAge 
	
		Description
		-----------
		Displays a list of all Users and their Password's age (in days).

	.EXAMPLE	
		Get-PasswordAge -Quiet

		Description
		-----------
		Displays a list of Users that have expired passwords only. Exports that 
		list to the global variable $ExpiredUserPassword.
	#>

	[CmdletBinding(SupportsShouldProcess=$true)]
	
	Param
	(
		[Parameter(HelpMessage="Only display accounts that are over ")] 
		[switch]$Quiet
	)

	BEGIN
	{
		if ($Quiet) {remove-variable -name ExpiredUserPassword -scope "global" -force -ea silentlycontinue}
		$users = gwmi win32_useraccount | select -expand Name | sort
		if ($Quiet -eq $false) {write-host ""}
	}

	PROCESS
	{
		foreach ($user in $users)
		{
			$age = [math]::Round(([ADSI]"WinNT://localhost/$user").PasswordAge[0] /86400)
			if ($Quiet -eq $true)
			{
				if ($age -gt "360")
				{
					$global:ExpiredUserPassword = @($global:ExpiredUserPassword + "$user")
				}
			}
			elseif ($age -gt "360")
			{
				write-host "User: " -nonewline
				write-host "$user" -foreground "Red" -nonewline
				write-host " has a password that is " -nonewline
				write-host "$age" -foreground "Red" -nonewline
				write-host " days old."
			}
			elseif ($age -gt "300" -and $age -lt "360")
			{
				write-host "User: " -nonewline
				write-host "$user" -foreground "Yellow" -nonewline
				write-host " has a password that is " -nonewline
				write-host "$age" -foreground "Yellow" -nonewline
				write-host " days old."
			}
			else
			{
				write-host "User: " -nonewline
				write-host "$user" -foreground "Green" -nonewline
				write-host " has a password that is " -nonewline
				write-host "$age" -foreground "Green" -nonewline
				write-host " days old."
			}
		}
	}
	
	END
	{
		if ($global:ExpiredUserPassword -ne $Null -and $quiet -eq $true){$global:ExpiredUserPassword | foreach-object {write-host "User: $_ has an expired password." -foreground "Red"}}
		if ($Quiet -eq $false) {write-host ""}
	}
}
