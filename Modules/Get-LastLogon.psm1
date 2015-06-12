Function Get-LastLogon
{
    <#
    .SYNOPSIS
        Gets last logon time for all local users and lists dormant accounts.
        
    .DESCRIPTION
        This function was created for the puprose of determining the last logon tim for local users,
        and to verify if they are considered 'dormant'. If the user has not logged on within the
        last 35 days, they are marked as dormant. The "LastLogin" field is displayed in DAYS.
        
    .PARAMETER ComputerName
        One or more computers to retrieve last logon information from.
        
    .PARAMETER Dormant
        If used, displays only accounts considered dormant (not logged in within 35 days).
        
    .EXAMPLE
        Get-LastLogon -ComputerName server01
        
        Description
        -----------
        Displays last logon time (in DAYS), status of the account (disabled or not), password requirement,
        and dormant status on computer 'server01'.
        
    .EXAMPLE
        Get-LastLogon -Computername (Get-Content .\servers.txt)
        
        Description
        -----------
        Displays last logon time (in DAYS), status of the account (disabled or not), password requirement,
        and dormant status for all computers listed in 'servers.txt'.
    
    .EXAMPLE
        Get-LastLogon -ComputerName server01 -Dormant
        
        Description
        -----------
        Displays 'dormant' accounts on computer 'server01'.
        
    .NOTES
        NAME......:  Get-LastLogon.psm1
        AUTHOR....:  Micah Battin (micah.o.battin@gmail.com)
        AUTHOR....:  Wesley Tomlinson (tomlinson.wesley@gmail.com)
        DATE......:  05 JUNE 2013
    #>

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
        $col1 = New-Object system.Data.DataColumn "ComputerName",([string])
        $col2 = New-Object system.Data.DataColumn "UserName",([string])
        $col3 = New-Object system.Data.DataColumn "LastLogin",([string])
	$col4 = New-Object system.Data.DataColumn "Disabled",([string])
	$col5 = New-Object system.Data.DataColumn "PasswordRequired",([string])
	$col6 = New-Object system.Data.DataColumn "Dormant",([string])
        $table.columns.add($col1)
        $table.columns.add($col2)
        $table.columns.add($col3)
	$table.columns.add($col4)
	$table.columns.add($col5)
	$table.columns.add($col6)
    }

    PROCESS
    {
         foreach ($Computer in $Computername)
         {
             $UserInfo = ([ADSI]"WinNT://$Computer").Children | where {$_.SchemaClassName -eq 'user'}
 
             foreach ($User in $UserInfo)
             {
                 $row = $table.NewRow()
                 $row.ComputerName = $Computer
                 $row.UserName = [string]$User.Name
                 $row.LastLogin = try{new-timespan -start ([datetime]([string]$User.LastLogin)) -end (get-date) | select -expandproperty "Days"}catch{"Never"}
                 $row.Disabled = (Get-WMIObject win32_UserAccount -ComputerName $Computer -Filter "LocalAccount='$True'" | Where-object { $_.Name -eq $row."UserName"}).Disabled
                 $row.PasswordRequired = (Get-WMIObject win32_UserAccount -ComputerName $Computer -Filter "LocalAccount='$True'" | Where-object { $_.Name -eq $row."UserName"}).PasswordRequired
                 $row.Dormant = if ($row."LastLogin" -gt "35"){"True"}else{"False"}
                 $table.Rows.Add($row)
             }

            $row = $table.NewRow()
            $row.ComputerName = ' '
            $row.UserName = ' '             
            $row.LastLogin = ' '
            $row.Disabled = ' '
            $row.PasswordRequired = ' '
            $row.Dormant = ' '
            $table.Rows.Add($row)

         }
    }

    END
    {
        If ($Dormant)
	{
	    $table | Select-Object "Computername","UserName","Dormant" | Where-Object {$_.Dormant -eq "True" -or $_.Dormant -eq ' '}
        }
        Else
        {
            $table
        }
    }
}
