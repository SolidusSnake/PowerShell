Function Modify-Account {

	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$True,ValueFromPipeline=$True)]
		[string[]]$ComputerName,
		#[parameter(Mandatory=$true)]
		#[string]$Username,
		[switch]$Disable
        #[switch]$Delete
	)

	BEGIN
	{	
		$AccountOptions = @{
			ACCOUNTDISABLE = 2
		}
	}

	PROCESS
	{
		# Process file created by function Get-DormantAccounts.
		$users = Get-Content "d:\u01\scripts\Account Checker\dormantTEST.txt" 

		# Process file containing user exclusion list
		$exUsers = Get-Content "d:\u01\scripts\Account Checker\ExcludeUserList.txt"
		
		# Declare user exclusion list hash
		$exUsersHash = @{}
		# Place $exUsers in hash
		foreach ($xuser in $exUsers)
		{
			if ($exUsersHash.ContainsKey($xuser))
			{
				# User already exist in hash which should not happen
			} else {
				# Add the user to the exclusion hash
				$exUsersHash.Add($xuser,"")
				write-output "Added $xuser to exclusion hash"
			}
		}
		
		# Process users
		foreach ($Computer in $Computername)
		{
		    foreach ($Username in $users)
			{
			    $User = $Username -replace'"'
				if ($exUsersHash.ContainsKey($User)) 
				{
					# Skip this guy in the exclusion list
					write-output "Skipped $User"
					Continue
				}

			    $UserDisable = [ADSI] "WinNT://$Computer/$User"
                #$userd = [ADSI] "WinNT://$Computer"
			
				# write-output $userd 
                #if ($Delete)
                #{
                #    $userd.Delete("User", $User)
                #}

                if ($Disable)
                {
				    write-output "Disabled $User" 
                    # $UserDisable.InvokeSet("AccountDisabled", "True")
                    # $User.SetInfo()
				}
			}
		
		}

	}
	
	END
	{
	}
}

Function Get-DormantAccounts
{
    [CmdletBinding(SupportsShouldProcess=$true)]

    Param
    (
    [Parameter(ValueFromPipeline=$true,Position=0,HelpMessage="Specify one or more server names to gather information from.")]
    [string[]]$Computername="$env:computername",
	[switch]$Dormant
    )

    BEGIN
    {
        $table = New-Object system.Data.DataTable "Table"
        $col1 = New-Object system.Data.DataColumn "UserName",([string])
        $col2 = New-Object system.Data.DataColumn "LastLogin",([string])
        $table.columns.add($col1)
        $table.columns.add($col2)
    }

    PROCESS
    {
         foreach ($Computer in $Computername)
         {
             $UserInfo = ([ADSI]"WinNT://$Computer").Children | where {$_.SchemaClassName -eq 'user'}
 
             foreach ($User in $UserInfo)
             {
                 $row = $table.NewRow()
                 $row.UserName = [string]$User.Name
                 $row.LastLogin = try{new-timespan -start ([datetime]([string]$User.LastLogin)) -end (get-date) | select -expandproperty "Days"}catch{"Never"}
                 #$row.LastLogin = try{New-TimeSpan -Start ($User.Lastlogin).Ticks -end (Get-Date).Ticks | Select -ExpandProperty "Days"}catch{"Never"}
                 $table.Rows.Add($row)
             }

            $row = $table.NewRow()
            $row.UserName = ' '             
            $row.LastLogin = ' '
            $table.Rows.Add($row)

         }
    }

    END
    {
    $table
    }
}

Get-DormantAccounts | Select-Object Username,@{l='LastLogin';e={$_.LastLogin -as [int]}} | Where-Object {$_.LastLogin -gt "35" -and $_.LastLogin -ne $null} | select username | Export-Csv "D:\U01\scripts\Account Checker\dormantTEST.csv" -NoTypeInformation -Force

Get-Content "d:\u01\scripts\Account Checker\dormantTEST.csv" | Select-Object -Skip 1 | Set-Content "D:\u01\scripts\Account Checker\dormantTEST.txt"

Modify-Account -ComputerName localhost -Disable
