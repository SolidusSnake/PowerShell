Function Find-Matches {                        

    Param($Pattern)
    Process {
    $_ | Select-String -Pattern $Pattern -AllMatches |
    Select-Object -ExpandProperty matches |
    Select-Object -ExpandProperty value
    }
}

if ((Get-WmiObject win32_computersystem).partofdomain -eq $true) {
    $LogFileExists = [System.Diagnostics.EventLog]::SourceExists("PTHScript")
    if ($LogFileExists -ne $TRUE){
    New-EventLog -LogName System -Source "PTHScript"
}

$dom = $env:USERDOMAIN
[xml]$CustomView = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">
	*[System[(EventID=4624) or (EventID=4625)]]
	and
	*[System[TimeCreated[timediff(@SystemTime)&lt;= 3600000]]]
	and
	*[EventData[Data[@Name='LogonType'] and (Data='3')]]
	and
	*[EventData[Data[@Name='AuthenticationPackageName'] = 'NTLM']]
	and
	*[EventData[Data[@Name='TargetUserName'] != 'ANONYMOUS LOGON']]
	and
	*[EventData[Data[@Name='TargetDomainName'] != '$dom']]
    and
    *[EventData[Data[@Name='WorkstationName'] !='xxxxxx' and Data[@Name='WorkstationName'] !='yyyyyy']]
    
    </Select>
   </Query>
</QueryList>
"@

$events = Get-WinEvent -FilterXML $CustomView
$events | ForEach-Object {$tempmessage=$_.message;

If ($tempmessage -ne $NULL){
    $Name = $tempmessage | Find-Matches -Pattern "Account Name:\s+\S+"
    If ($Name.Count -eq 2) { $account = $Name[1]}
    $Domain = $tempmessage | Find-Matches -Pattern "Account Domain:\s+\w+"
    $Sys = $tempmessage | Find-Matches -Pattern "Workstation Name:\s+\w+"
    $account = $account -replace '	'
    $Domain = $Domain -replace '	'
    $Sys = $Sys -replace '	'
    $EventCheck = "The following user attempted to login; Please validate: ", $account, "--", $Domain, "--", $Sys, "--", "AlertMSG2"
    write-eventlog -logname System -source "PTHScript" -eventid 55555 -entrytype "Warning" -message "$EventCheck"}}
}
