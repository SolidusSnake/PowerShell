function Generate-Pass {


	param (
		[int]$charLength = 15,
		[int]$upper = 2,
		[int]$number = 2,
		[int]$special = 2,
		[string]$salt = $null
	)
	
	
	if (($upper + $number + $special) -gt $charLength) {
		return $false
	}

	$lowerLength = $charLength - $special - $number - $upper

	$charSet = @{
		1 = @{
			'set' = @('a','b','c','d','e','f','g','h','j','k','m','n','p','q','r','s','t','u','v','w','x','z');
			'charLength' = $lowerLength
		};
		2 = @{ 
			'set' = @('A','B','C','D','E','F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y','Z');
			'charLength' = $upper
		};
		3 = @{
			'set' = @('2','3','4','5','6','7','8','9');
			'charLength' = $number
		};
		4 = @{
			'set' = @('!','@','#','%','^','&','*',')','(','-','+','_','\');
			'charLength' = $special
		}
	}

	$pass = "";


	For ($i=0; $i -lt ($charSet.Count + 1); $i++) {
		for ($x = 1; $x -le $charSet[$i].charLength; $x++) {
			$randNumber = Get-Random -Max $charSet[$i].set.Length
			$pass += $charSet[$i].set[$randNumber]
		}
	}


	$finalPass = (($pass.ToCharArray() | Get-Random -Count $pass.Length) -join '');
	
	return $($finalPass + $salt);

}

write-host '________________________________________'
Write-Host "`n
Random Password 1: " -foregroundcolor green -nonewline; write-host $(generate-pass); write-host
'________________________________________'


Write-Host "`n
Random Password 2: " -foregroundcolor green -nonewline; write-host $(generate-pass); write-host
'________________________________________'


Write-Host "`n
Random Password 3: " -foregroundcolor green -nonewline; write-host $(generate-pass); write-host
'________________________________________'


Write-Host "`n
Random Password 4: " -foregroundcolor green -nonewline; write-host $(generate-pass); write-host
'________________________________________'


Write-Host "`n
Random Password 5: " -foregroundcolor green -nonewline; write-host $(generate-pass); write-host
'________________________________________'



















read-host "`n`nPress Enter When Done!!!!" 