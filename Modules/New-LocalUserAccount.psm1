Function New-LocalUserAccount 
{
  <#
	.SYNOPSIS
		Creates a new local user and adds to security groups.
		
	.DESCRIPTION
		This function was designed for the purpose of creating a local user account on remote systems, 
		and adding that account to defined security groups. The password is automatically set to expire 
		on first logon. 	 
		
	.PARAMETER ComputerName
		Specifies local or remote computer to modify. Accepts values from the pipeline.
		
	.PARAMETER Password
		If used, will prompt for password to be set. Input will be as a secure string.
		
	.PARAMETER Username
		Sets user to create.

	.PARAMETER Description
		Sets user description.
	
	.PARAMETER FullName
		Sets user full name.
		
	.PARAMETER AddToGroup
		Adds user to security group(s).
		
	.EXAMPLE
		New-LocalUserAccount -ComputerName (Get-Content .\servers.txt) -Username Test.Account -Password -FullName "Test Account" -Description "Account used for testing" -AddToGroup "Remote Desktop Users","Administrators","NEW_GRP"
		
		Description
		-----------
		Creates a new user called 'Test.Account' on all servers listed in the ".\servers.txt" file, 
		sets the user's full name, description, password, and adds the user to the 
		Remote Desktop Users, Administrators, and NEW_GRP security groups.
		
	.EXAMPLE
		New-LocalUserAccount -ComputerName server01 -UserName Test.Account -Password -FullName "Test Account" -Description "Account used for testing" -AddToGroup "Remote Desktop Users","Administrators","NEW_GRP"
		
		Description
		-----------
		Creates a new user called 'Test.Account' on the single server, 'server01', sets the user's full name, 
		description, password, and adds the user to the Remote Desktop Users, Administrators, and NEW_GRP security groups.
	#>

	[CmdletBinding(SupportsShouldProcess=$true)]
	param (
		[Parameter(Mandatory=$True,ValueFromPipeline=$True)]
		[string[]]$ComputerName,
		[Parameter(Mandatory=$True)] 
		[string]$UserName,
		[Parameter(Mandatory=$True)] 
		[string]$Description,
		[Parameter(Mandatory=$True)]
		[string]$FullName,
		[Parameter(Mandatory=$True)]
		[string[]]$AddToGroup,
		[switch]$Password
	)

	BEGIN
	{
		if ($Password) 
		{
			$Passw = read-host "Enter a new password" -assecurestring
		}

		$AccountOptions = @{
			ACCOUNTDISABLE = 2; LOCKOUT = 16; PASSWD_CANT_CHANGE = 64; NORMAL_ACCOUNT = 512; DONT_EXPIRE_PASSWD = 65536
		}
	}

	PROCESS
	{

		Foreach ($Computer in $Computername)
		{
			if ($Passw) 
			{
				$Pass = [Runtime.InteropServices.marshal]::PtrToStringAuto([Runtime.InteropServices.marshal]::SecureStringToBSTR($Passw))
			}
			$Comp = [ADSI]"WinNT://$computer"
			$User = $Comp.Create("User", $UserName)
			$User.SetPassword($Pass)
			If ($Description)
			{
				$User.Put("Description",$Description)
			}
			If ($FullName)
			{
				$User.Put("FullName",$FullName)
			}
			$User.SetInfo()
			$Usern = [ADSI] "WinNT://$Computer/$Username"
			$usern.UserFlags = $AccountOptions.PASSWD_CANT_CHANGE -band $AccountOptions.DONT_EXPIRE_PASSWD
			$usern.PasswordExpired = 1
			Foreach ($AddGrp in $AddToGroup)
			{
				([ADSI]"WinNT://$Computer/$AddGrp,group").Add("WinNT://$Computer/$UserName,user")
			}
			$Usern.SetInfo()

		}

	}

	END
	{
	}

}
