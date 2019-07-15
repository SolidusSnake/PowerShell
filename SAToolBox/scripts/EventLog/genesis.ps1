

cls


$gentime = Read-Host "Enter time genesis to search around in mm/dd/yyyy hh:mm format (server time)"
$genmin = Read-Host "Enter plus and minus interval (in minutes) to search around"

# see if gentime is lacking year...if so, we need to add it
If ($gentime -match "^\d{1,2}\/\d{1,2}\ \d{1,2}:\d{1,2}") {
	$gentime = $((($gentime -split " ")[0] + "/" + (get-date -format yyyy)) + " " + ($gentime -split " ")[1])
}

$gentime = (get-date $gentime)

$gentime_min = $gentime.AddMinutes([int]$genmin-([int]$genmin*2))
$gentime_max = $gentime.AddMinutes([int]$genmin)

Write-Host $("Locating events from " + $gentime_min + " to " + $gentime_max)

Write-Host "Events:`n"

$winevents = @()
$winevents += Get-WinEvent -filterhashtable @{logname='application';startTime=$gentime_min;endtime=$gentime_max} -erroraction 'silentlycontinue' | select LogName,Id,TimeCreated,Message
$winevents += Get-WinEvent -filterhashtable @{logname='security';startTime=$gentime_min;endtime=$gentime_max} -erroraction 'silentlycontinue' | select LogName,Id,TimeCreated,Message
$winevents += Get-WinEvent -filterhashtable @{logname='system';startTime=$gentime_min;endtime=$gentime_max} -erroraction 'silentlycontinue' | select LogName,Id,TimeCreated,Message 

$winevents | sort timecreated | fl | out-host -paging
#$winevents | sort timecreated | out-gridview

Read-Host "Done."