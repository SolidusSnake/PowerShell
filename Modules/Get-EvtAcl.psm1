Function Get-EvtAcl
{
	<#
	.SYNOPSIS
		Gets event log ACLs from a predefined location.
		
	.DESCRIPTION
		This function was created for the purpose of ensuring proper permissions
		are applied to event logs. By default, this function searches the default
		directory for 2008 R2, "C:\Windows\System32\Winevt\Logs". If applicable, 
		change the $LogLocation variable to search a different directory. Searches
		can be separated by commas, or retrieved from a list. 
		
	.PARAMETER ComputerName
		One or more computers to retrieve ACLs on.
		
	.PARAMETER LogName
		Event log filename, such as Security, Application, or System
		
	.EXAMPLE
		Get-EvtAcl -ComputerName server01 -LogName Security
		
		Description
		-----------
		Displays ACLs for file C:\windows\system32\winevt\logs\Security.evtx
		on server "server01".
		
	.EXAMPLE
		Get-EvtAcl -ComputerName server01,server02 -LogName Security
		
		Description
		-----------
		Displays ACLs for C:\windows\system32\winevt\logs\Security.evtx
		on servers "server01" and "server02".
		
	.EXAMPLE
		$serverlist = Get-Content .\servers.txt
		Get-EvtAcl - ComputerName $serverlist -LogName Security
		
		Description
		-----------
		Displays ACLs for C:\windows\system32\winevt\logs\Security.evtx
		for all servers listed in ".\servers.txt".
	#>
	
	[CmdletBinding(SupportsShouldProcess=$true)]

	Param
	(
	[Parameter(Mandatory=1,Position=1,HelpMessage="Specifiy event log to retrieve.")]
	[string]$LogName,
	[Parameter(ValueFromPipeline=$true)]
	[string[]]$ComputerName="localhost"
	)

	Begin
	{
        #Variables
        $LogLocation = "C:\windows\system32\winevt\logs"

		$table = New-Object system.Data.DataTable "Table"
		$col1 = New-Object system.Data.DataColumn "ComputerName",([string])
		$col2 = New-Object system.Data.DataColumn "Path",([string])
		$col3 = New-Object system.Data.DataColumn "ACL",([string])
		$table.columns.add($col1)
		$table.columns.add($col2)
		$table.columns.add($col3)
	}

	PROCESS
	{
		foreach ($Computer in $ComputerName)
		{
			if ((Test-Connection -ComputerName $computer -quiet) -eq $true)
			{
				$path = "$LogLocation" + "\" + "$LogName" + ".evtx"
				$search = Invoke-Command -ComputerName $computer -ScriptBlock {param($path) Get-Acl $path} -ArgumentList $path
				foreach ($file in $search)
				{
					$row = $table.NewRow()
					$row.ComputerName = $file.PSComputername
					$row.Path = $file.PSPath
					$row.ACL = $file.AccessToString
					$table.rows.Add($row)
				}
			}
			else
			{
				Write-Error "$computer cannot be reached. Please check that this system is online."
			}
		}
	}

	END
	{
		$table
	}
}
