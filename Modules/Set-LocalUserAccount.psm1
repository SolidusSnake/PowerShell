Function Set-LocalUserAccount {

	<#
	.SYNOPSIS
		Sets properties for a given local user.
		
	.DESCRIPTION
		This function was created for the purpose of modifying local user account
		properties. These properties include: description, full name, password,
		and account flags. 
		
	.PARAMETER ComputerName
		Specifies local or remote computer to modify.
		
	.PARAMETER Password
		If used, will prompt for password to be set. Input will be as a secure string.
		
	.PARAMETER Username
		Sets user to modify.

	.PARAMETER FullName
		Sets users 'full name'.
	
	.PARAMETER Description
		Sets user description.
		
	.PARAMETER PasswordChangeAtNextLogon
		Sets account flag 'user must change password on next logon' to TRUE.
		
	.PARAMETER CannotChangePassword
		Sets account flag 'user cannot change password' to TRUE.
	
	.PARAMETER PasswordNeverExpires
		Sets account flag 'password never expires' to TRUE.
	
	.PARAMETER Enable
		Sets account flag 'account disabled' to FALSE.
		
	.PARAMETER Disable
		Sets account flag 'account disabled' to TRUE.
	
	.PARAMETER Unlock
		Sets account flag 'account is locked out' to FALSE.
		
	.EXAMPLE
		Set-LocalUserAccount -ComputerName (Get-Content .\servers.txt) -Username xadministrator -Password -PasswordChangeAtNextLogon
		
		Description
		-----------
		Sets new password for user 'xadministrator' on all computers in 'servers.txt' and requires password 
		to be changed on next logon.
		
	.EXAMPLE
		Set-LocalUserAccount -ComputerName server01 -UserName xadministrator -Password -PasswordChangeAtNextLogon
		
		Description
		-----------
		Sets new password for user 'xadministrator' on computer "server01" and requires password to be 
		changed on next logon.
		
	.EXAMPLE
		Set-LocalUserAccount -ComputerName server01 -UserName xadministrator -PasswordNeverExpires 
		
		Description
		-----------
		Sets password to never expire for user "xadministrator" on computer "server01".
		
	.EXAMPLE
		Set-LocalUserAccount -ComputerName server01 -UserName xadministrator -Unlock
		
		Description
		-----------
		Unlocks user account "xadministrator" on computer "server01".

	.EXAMPLE
		Get-Content ".\Computers.txt" | Set-LocalUserAccount -UserName xadministrator -Unlock

		Description
		-----------
		Uses a list of computers from the pipeline to unlock the user account "xadministrator" on 
		multiple computers.
		
	.NOTES
		NAME......:  Set-LocalUserAccount.psm1
		AUTHOR....:  Micah Battin (micah.o.battin@gmail.com)
		AUTHOR....:  Wesley Tomlinson (tomlinson.wesley@gmail.com)
		DATE......:  05 JUNE 2013
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$True,ValueFromPipeline=$True)]
		[string[]]$ComputerName,
		[parameter(Mandatory=$true)]
		[string]$Username,
		[string]$Description,
		[string]$FullName,
		[string[]]$AddToGroup,
		[string[]]$RemoveFromGroup,
		[switch]$Password,
		[switch]$PasswordChangeAtNextLogon,
		[switch]$CannotChangePassword,
		[switch]$PasswordNeverExpires,
		[switch]$Enable,
		[switch]$Disable,
		[switch]$UnLock,
		[switch]$ResetAllFlags
	)

	BEGIN
	{	
		if ($Password -eq $true) 
		{
			$Passw = read-host "Enter a new password" -assecurestring
		}
	
		if ($Enable -and $Disable) 
		{
			Write-Warning "Please use only -Enable or -Disable."; return
		}

		
		$AccountOptions = @{
			ACCOUNTDISABLE = 2; LOCKOUT = 16; PASSWD_CANT_CHANGE = 64; NORMAL_ACCOUNT = 512; DONT_EXPIRE_PASSWD = 65536
		}
	}

	PROCESS
	{
		foreach ($Computer in $Computername)
		{
			if ($Passw) 
			{
				$pass = [Runtime.InteropServices.marshal]::PtrToStringAuto([Runtime.InteropServices.marshal]::SecureStringToBSTR($Passw))
			}
	
			$user = [ADSI] "WinNT://$Computer/$Username"
		
			if ($Description) 
			{
				$user.Description = $Description
			}
		
			if ($FullName) 
			{
				$user.FullName = $FullName
			}
	
			if ($pass) 
			{
				$user.psbase.invoke("SetPassword", $pass)
				$user.psbase.CommitChanges()
			}
		
			if ($ResetAllFlags) 
			{
				$user.UserFlags = $user.UserFlags.Value -band $AccountOptions.NORMAL_ACCOUNT
			} 
			else 
			{
				# Disables "User cannot change password" and "Password never expires"
				if ($PasswordChangeAtNextLogon) 
				{	
					$user.UserFlags = $AccountOptions.PASSWD_CANT_CHANGE -band $AccountOptions.DONT_EXPIRE_PASSWD
					$user.PasswordExpired = 1
				} 
				else 
				{
					if ($CannotChangePassword) 
					{
						$user.PasswordExpired = 0
						$user.UserFlags = $user.UserFlags.Value -bor $AccountOptions.PASSWD_CANT_CHANGE
					} 
					if ($PasswordNeverExpires) 
					{
						$user.UserFlags = $user.UserFlags.Value -bor $AccountOptions.DONT_EXPIRE_PASSWD
					}	
				}
		
				if ($Enable) {$user.InvokeSet("AccountDisabled", "False")}
		
				if ($Disable) {$user.InvokeSet("AccountDisabled", "True")}
		
				if ($UnLock) {$user.IsAccountLocked = $false}
			}
			$user.SetInfo()
		}

		Foreach ($AddGrp in $AddToGroup)
		{
			([ADSI]"WinNT://$Computer/$AddGrp,group").Add("WinNT://$Computer/$UserName,user")
		}

		Foreach ($RemoveGrp in $RemoveFromGroup)
		{
			([ADSI]"WinNT://$Computer/$RemoveGrp,group").Remove("WinNT://$Computer/$UserName,user")
		}
	}
	
	END
	{
	}
}
