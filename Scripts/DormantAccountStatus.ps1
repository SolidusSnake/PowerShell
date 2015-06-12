### EXCLUSION LIST ###
### USE FORMAT "username|username2" or "usern*|usernam*" ###
$list = "user1|user2|user3"


### DON'T EDIT BELOW THIS LINE ###

$date = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd")

### Create directory if it does not exist
if ((Test-Path -Path "$env:HOMEDRIVE\LocalAccountStatus\") -ne $true)
{
    New-Item -ItemType directory -Path $env:HOMEDRIVE\LocalAccountStatus
}

### Report path and filename
$cship = $env:COMPUTERNAME
$reportPath = "$env:HOMEDRIVE\LocalAccountStatus\"
$reportName = "$cship" + "_LocalAccountStatus_$date.csv"

Clear
$ErrorActionPreference = "Continue"

Function Modify-Account 
{

	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$True,ValueFromPipeline=$True)]
		[string[]]$ComputerName="$env:COMPUTERNAME",
		[string]$Username,
		[switch]$Disable,
        [switch]$Delete
	)

	BEGIN
	{	
		$AccountOptions = @{
			ACCOUNTDISABLE = 2
		}
	}

	PROCESS
	{
		foreach ($Computer in $Computername)
		{
				
			$user = [ADSI] "WinNT://$Computer/$Username"
            $userd = [ADSI] "WinNT://$Computer"
		
            if ($Delete)
            {
                $userd.Delete("User", $Username)
            }

            if ($Disable)
            {
                $user.InvokeSet("AccountDisabled", "True")
                $user.SetInfo()
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
    [string[]]$Computername="$env:computername"
    )

    BEGIN
    {
        $table = New-Object System.Data.DataTable "Table"
        $col0 = New-Object System.Data.DataColumn "HostName",([string])
        $col1 = New-Object System.Data.DataColumn "UserName",([string])
        $col2 = New-Object System.Data.DataColumn "SID",([string])
        $col3 = New-Object System.Data.DataColumn "LastLogin",([string])
        $col4 = New-Object System.Data.DataColumn "Disabled",([string])
        $col5 = New-Object System.Data.DataColumn "Excluded",([string])
        $col6 = New-Object System.Data.DataColumn "TimeGenerated",([string])
        $table.columns.add($col0)
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
                 $row.HostName = $env:computername
                 $row.UserName = [string]$User.Name
                 $row.SID = (Get-WmiObject -Class win32_UserAccount -ComputerName $Computer | Where-Object { $_.Name -eq $row."UserName"}).Sid
                 $row.LastLogin = try{New-TimeSpan -start ([datetime]([string]$User.LastLogin)) -end (Get-Date) | select -expandproperty "Days"}catch{"Never"}
                 $row.Disabled = (Get-WMIObject win32_UserAccount -ComputerName $Computer -Filter "LocalAccount='$True'" | Where-object { $_.Name -eq $row."UserName"}).Disabled
                 $row.Excluded = If ($user.name -match "$list"){[Bool]$True} Else{[Bool]$False}
                 $row.TimeGenerated = ((Get-Date).ToUniversalTime()).ToString("yyyy-MM-dd @ hh:mm:ss Z")
                 $table.Rows.Add($row)
             }

            $row = $table.NewRow()
            $row.HostName = ' '
            $row.UserName = ' '
            $row.SID = ' '             
            $row.LastLogin = ' '
            $row.Disabled = ' '
            $row.TimeGenerated = ' '
            $table.Rows.Add($row)

         }
    }

    END
    {
    $table
    }
}

### Daily report
Get-DormantAccounts | Export-Csv -Path "$reportPath$reportName" -NoTypeInformation

### If using 3.0 or higher, and want to keep a single CSV
#Get-DormantAccounts | Export-Csv -Path "$reportPath$reportName" -NoTypeInformation -Append

Get-DormantAccounts | Select-Object Username,@{l='LastLogin';e={$_.LastLogin -as [int]}} | Where-Object {$_.LastLogin -gt 30 -and $_.LastLogin -ne $null -and $_.username -notmatch "$list"} | select UserName |  Export-Csv $env:HOMEDRIVE\LocalAccountStatus\Dormant.csv -NoTypeInformation -Force
(Get-Content $env:HOMEDRIVE\LocalAccountStatus\Dormant.csv | Select-Object -Skip 1) | Set-Content $env:HOMEDRIVE\LocalAccountStatus\Dormant.txt
(Get-Content $env:HOMEDRIVE\LocalAccountStatus\Dormant.txt) | Foreach-Object {$_ -replace "\""", ""} | Set-Content $env:HOMEDRIVE\LocalAccountStatus\Disable.txt
Remove-Item $env:HOMEDRIVE\LocalAccountStatus\Dormant.txt
Remove-Item $env:HOMEDRIVE\LocalAccountStatus\Dormant.csv

Get-DormantAccounts | Select-Object Username,@{l='LastLogin';e={$_.LastLogin -as [int]}} | Where-Object {$_.LastLogin -gt 45 -and $_.LastLogin -ne $null -and $_.username -notmatch "$list"} | select UserName |  Export-Csv $env:HOMEDRIVE\LocalAccountStatus\Dormant.csv -NoTypeInformation -Force
(Get-Content $env:HOMEDRIVE\LocalAccountStatus\Dormant.csv | Select-Object -Skip 1) | Set-Content $env:HOMEDRIVE\LocalAccountStatus\Dormant.txt
(Get-Content $env:HOMEDRIVE\LocalAccountStatus\Dormant.txt) | Foreach-Object {$_ -replace "\""", ""} | Set-Content $env:HOMEDRIVE\LocalAccountStatus\Delete.txt
Remove-Item $env:HOMEDRIVE\LocalAccountStatus\Dormant.txt
Remove-Item $env:HOMEDRIVE\LocalAccountStatus\Dormant.csv

### Disable users
$userdis = Get-Content $env:HOMEDRIVE\LocalAccountStatus\Disable.txt
$userdis | ForEach-Object {Modify-Account -ComputerName localhost -Username $_ -Disable}

### Delete users
$userdel = Get-Content $env:HOMEDRIVE\LocalAccountStatus\Delete.txt
$userdel | ForEach-Object {Modify-Account -ComputerName localhost -Username $_ -Delete}

Remove-Item $env:HOMEDRIVE\LocalAccountStatus\Disable.txt
Remove-Item $env:HOMEDRIVE\LocalAccountStatus\Delete.txt
