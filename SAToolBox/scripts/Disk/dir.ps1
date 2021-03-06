

param (
	[ValidateScript({ Test-Path $_ })]
	$currentDir = 'C:\program files',
	[hashtable]$hashcache = @{}
)

function gci-calcsize {
	param (
		$dirListing = $NULL
	)

	$fileLen = 0;
	$dirListing | ? { $_.PSIsContainer -eq $False } | % {
		$fileLen += $_.length
	}

	Return [float]$fileLen
	
}

function gci-cacheaware {
	param (
		[ValidateScript({ Test-Path $_ })]
		[string]$requestedDir = $currentDir
	)

	If (-not ($script:hashcache.ContainsKey($requestedDir))) {
		$curDirListing = Get-ChildItem $requestedDir | ? { $_.PSIsContainer -eq $True } | Select Name,@{N='Size (Mb)';E={ [math]::round(((gci-calcsize (get-childitem $_.fullname -recurse))/1Mb),2)}}
		$script:hashcache.Add($requestedDir,$curDirListing)
	}

	Return $script:hashcache
}

$header = @"
 ______   ___   ______    _______  ___   _______  _______ 
|      | |   | |    _ |  |       ||   | |       ||       |
|  _    ||   | |   | ||  |  _____||   | |____   ||    ___|
| | |   ||   | |   |_||_ | |_____ |   |  ____|  ||   |___ 
| |_|   ||   | |    __  ||_____  ||   | | ______||    ___|
|       ||   | |   |  | | _____| ||   | | |_____ |   |___ 
|______| |___| |___|  |_||_______||___| |_______||_______|
`n`n
"@


$ErrorActionPreference = 'SilentlyContinue'
Clear-Host
Write-Host $header
$curgci = gci-cacheaware -requestedDir $script:currentDir
$curgci.$script:currentDir | Sort 'Size (Mb)' -Desc | Out-Host -Paging

do {	
	$a = read-host 'Select a Dir ([b]ack or [f]orward) or [q]uit'

	If ($a -eq 'q') { 
		exit
	} elseif ($a -eq 'b') { 
		$script:currentDir = $((Split-Path -Path $script:currentDir -Parent))
	} elseif ($a -eq 'gc') {
		$script:hashcache | Out-Host -Paging
		continue;
	} elseif ($a -eq 'f') {
		$script:currentDir = ($script:hashcache.GetEnumerator() | Select -First 1).Name
	} elseif ($a -eq 'cc') {
		$script:hashcache = @{}
		continue;
	} elseif (-not (Test-Path $a)) {
		$script:currentDir = (Get-Childitem $script:currentDir | ? { $_.PSIsContainer -eq $True -and $_.name -match $a } | Select -First 1).fullname
	} else {
		$script:currentDir = $a
	}

	Clear-Host
	Write-Host $header
	Write-Host $('You selected: ' + $script:currentDir)
	$curgci = gci-cacheaware -requestedDir $script:currentDir
	$curgci.$script:currentDir | Sort 'Size (Mb)' -Desc | Out-Host -Paging
} while (-1)
