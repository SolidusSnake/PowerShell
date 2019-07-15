

cls

Write-Host "Application Errors:`n"
Get-WinEvent -filterhashtable @{'level'=2;'logname'='application'} -erroraction 'silentlycontinue' | select LogName,Id,TimeCreated,Message | select -first 100 | fl | out-host -paging

Write-Host "System Errors:`n"
Get-WinEvent -filterhashtable @{'level'=2;'logname'='system'} -erroraction 'silentlycontinue' | select LogName,Id,TimeCreated,Message | select -first 100 | fl | out-host -paging

Write-Host "Security Errors:`n"
Get-WinEvent -filterhashtable @{'level'=2;'logname'='security'} -erroraction 'silentlycontinue' | select LogName,Id,TimeCreated,Message | select -first 100 | fl | out-host -paging

Read-Host "Done."