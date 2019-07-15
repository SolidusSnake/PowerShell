

$header = @"
 _______  _______  __   __ 
|       ||       ||  | |  |
|       ||    _  ||  | |  |
|       ||   |_| ||  |_|  |
|      _||    ___||       |
|     |_ |   |    |       |
|_______||___|    |_______|
`n`n
"@


cls

write-host $header

Write-host "getting processor data"
$procData = Get-WmiObject –class Win32_processor
[int]$numCores = (($procData) | select numberofcores | measure-object numberofcores -sum).sum
Write-Host ("Number of cores found: " + $numCores)


while (1) {
	cls
	write-host $header

	$procwatch = Read-Host "Enter a process to watch (i.e. oracle). Or, enter q to quit."

	# Give us a chance to exit
	If ($procwatch -eq "q") { cls; exit; }

	$procdata = Get-Process $($procwatch + "*") -erroraction "silentlycontinue"

	If ($procdata -ne $null) {
		while (1) {
			if ($Host.UI.RawUI.KeyAvailable -and ("q" -eq $Host.UI.RawUI.ReadKey("IncludeKeyUp,NoEcho").Character)) {
				break;				
			}

			[float]$procTime = 0
			$Counter = "\Process(" + $procwatch + "*)\% Processor Time"
			$cdata = Get-Counter $Counter -erroraction "silentlycontinue"
			$cdata | % { 
				$csamples = $_.countersamples
				$csamples | % {
					#If ($_.path -match $("\(" + $procwatch + "\)\\")) {
						$procTime += $_.cookedvalue
					#} 
				}
			}
			
			
			$proctime = ($proctime/$numCores)
		
			write-progress -id 0 -status $("% Processor Time TOTAL [" + [math]::round($procTime,2) + "%]") -activity $($procwatch + " [" + $procdata.count + " instance(s)]") -percentcomplete $procTime
			start-sleep -milliseconds 500
		}

	} else {
		Write-Host $('The process: ' + $procwatch + ' was not found; try again...')
	}

}


Read-Host "Done."