Function Remove-LocalUserAccount 
{
    <#
    .SYNOPSIS
        Removes a local user account from remote machines.

    .DESCRIPTION
        This function was created for the purpose of removing
        local user accounts on remote machines.

    .PARAMETER Computername
        Specifies local or remote computer to remove the user from.

    .PARAMETER UserName
        Specifies user to remove.

    .EXAMPLE
        Remove-LocalUserAccount -ComputerName server01 -Username user01

        Description
        -----------
        Removes the user 'user01' from the computer 'server01'.

    .EXAMPLE
        Remove-LocalUserAccount -ComputerName (Get-Content .\servers.txt) -Username user01

        Description
        -----------
        Removes the user 'user01' from all computers listed in 'servers.txt'.
    #>


	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$True,ValueFromPipeline=$True)]
		[string[]]$ComputerName,
		[parameter(Mandatory=$true)]
		[string]$Username
    )

    BEGIN
    {
    }

    PROCESS
    {
        foreach ($Computer in $ComputerName)
        {
            $Server = [ADSI]"WinNT://$Computer"
            $Server.Delete("User", $Username)
        }
    }

    END
    {
    }
}
