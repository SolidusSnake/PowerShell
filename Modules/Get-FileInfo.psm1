Function Get-FileInfo
{
	<#
	.SYNOPSIS
		Gets information on a one or more files from one or more computers.

	.DESCRIPTION
		This function was created for the purpose of assisting with applying 
		STIGS to systems. It will fetch any file on the c: that is specified
		and will return the File name, File Path, Version and Host Name that
		it came from.

	.PARAMETER FileName
		One or more files to be searched for. This paramater accepts only 
		filenames and not paths.

	.PARAMETER ComputerName
		One or more computers to search for files on. 

	.EXAMPLE
		Get-FileInfo -Filename "File1","File2" -ComputerName "Computer1","Computer2" 
	
		Description
		-----------
		Displays a table of information on File1 and File2 on both Computer1 
		and Computer2.

	.EXAMPLE	
		Get-Content "Computers.txt" | Get-FileInfo -FileName (Get-Content "files.txt") | Format-List 

		Description
		-----------
		Gets information on a list of files from a list of computers and formats
		them as a list.
	
	.EXAMPLE
		Get-FileInfo -Computer (Get-Content serverlist.txt) -File (Get-Content filelist.txt) | Export-Csv "myCSVreport.csv"
		
		Description
		-----------
		Gets information on a list of files from a list of computers and exports the results as a .csv document.

	.EXAMPLE	
		Get-Content ".\myfolder\Computers.txt" | Get-FileInfo "pdm.dll" | Export-CSV "myCSVreport.csv"

		Description
		-----------
		Gets information on all instances of "pdm.dll" for a list of computers 
		and exports that list as a .csv documents.
		
	.NOTES
		NAME......:  Get-FileInfo.psm1
		AUTHOR....:  Micah Battin (micah.o.battin@gmail.com)
		AUTHOR....:  Wesley Tomlinson (tomlinson.wesley@gmail.com)
		DATE......:  10 MAY 2013
	#>

	[CmdletBinding(SupportsShouldProcess=$true)]
 
	Param
	(
	[Parameter(Mandatory=1,Position=0,HelpMessage="Specify one or more file names to search.")]
	[string[]]$FileName,
	[Parameter(ValueFromPipeline=$true)]
	[string[]]$ComputerName="localhost"
	)

	Begin
	{
        $ErrorActionPreference = "SilentlyContinue"
		$table = New-Object system.Data.DataTable "Table"
		$col1 = New-Object system.Data.DataColumn "FileName",([string])
		$col2 = New-Object system.Data.DataColumn "Version",([string])
		$col3 = New-Object system.Data.DataColumn "Directory",([string])
		$col4 = New-Object system.Data.DataColumn "Hostname",([string])
		$table.columns.add($col1)
		$table.columns.add($col2)
		$table.columns.add($col3)
		$table.columns.add($col4)
	}


	PROCESS
	{
		foreach ($Computer in $ComputerName)
		{
			if ((test-connection -computername $computer -quiet) -eq $true)
			{
                $search = Invoke-Command -ComputerName $computer -ScriptBlock {param($FileName)Get-ChildItem "C:\" -Include $FileName -Recurse} -ArgumentList (,$FileName)

			
				foreach ($file in $search)
				{
                		   	if ($file.directoryname -notlike "C:\Windows\winsxs\*")
					{
						        $version = (Get-Item $file.FullName).VersionInfo
							$row = $table.NewRow()
							$row.FileName = [string]$file.name
							$row.Version = [string]$version.FileMajorPart + "." + [string]$version.FileMinorPart + "." + [string]$version.FileBuildPart + "." + [string]$version.FilePrivatePart
							$row.Directory = [string]$file.directory
							$row.Hostname = (get-wmiobject win32_computersystem -computername $Computer | select -expandproperty "Name")
							$table.rows.Add($row)
					}
				}
			}
			else
			{
				write-error "$computer cannot be reached. Please check that this system is online."
			}
		}
	}

	END
	{
		$table
	}
}
