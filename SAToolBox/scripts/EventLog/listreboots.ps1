

cls

Write-Host "Scrubbing the System event log for reboot events...`n" 

Get-WinEvent -filterhashtable @{'logname'='system';id=6005,6006,6008,6009,1074,1076,1001} -erroraction 'silentlycontinue' | select id,TimeCreated,Message | fl | out-host -paging


Read-Host "Done."