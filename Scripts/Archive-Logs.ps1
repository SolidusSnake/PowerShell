Import-Module Pscx

$date = (Get-Date -uformat "%Y%m%d")
$logs = (Get-ChildItem D:\Windows\System32\Config\EventLogs\* -Include *Archive-Security*)
$ArchiveFile = "D:\Windows\System32\Config\EventLogs\Zipped\Archived-Security-" + $date + ".zip"
If (!(Test-Path $ArchiveFile)) { Set-Content $ArchiveFile ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18)) }

$logs | Write-Zip -Level 9 -OutputPath $ArchiveFile -append -FlattenPaths | Move-item d:\windows\system32\config\eventlogs\zipped\



## Remove original log files once they are archived ##
Remove-Item D:\Windows\System32\Config\EventLogs\* -Include *Archive-Security*
