<#
This will parse CSVs generated from Log Parser
It will check for the following criteria:
2 or more failed logon attemps from the same source
IP address, with different usernames and within a
1 minute window.
#>



$Path = Read-Host -Prompt "Where is the CSV that you need to sort?"
$Destination = Read-Host "Where do you want to save the resulting CSV File?"
$CSV = Import-CSV $Path
$CSV = $CSV | Where-Object {$_.User -ne "`t"}
$CSV = $CSV | Sort-Object {[datetime]$_.TimeGenerated}

$i=0
$Results = @()
ForEach ($Log in $CSV)
{
    If ((([datetime]$Log.TimeGenerated - [datetime]$CSV[($i - 1)].TimeGenerated).TotalMinutes -lt 1) -and ($i -gt 0) -and ($CSV[($i - 1)].IP -eq $Log.IP) -and ($CSV[($i - 1)].User -ne $Log.User))
    {
        $Results = $Results + $CSV[($i - 1)]
        $Results = $Results + $Log
    }
    $i++
}

$Results = $Results | Sort-Object {[datetime]$_.TimeGenerated} # -Unique 
$Results | Export-CSV $Destination -NoTypeInformation

