

cls

Write-Host "Application Warnings:`n"
Get-WinEvent -filterhashtable @{'level'=3;'logname'='application'} -erroraction 'silentlycontinue' | select LogName,Id,TimeCreated,Message | select -first 100 | fl | out-host -paging

Write-Host "System Warnings:`n"
Get-WinEvent -filterhashtable @{'level'=3;'logname'='system'} -erroraction 'silentlycontinue' | select LogName,Id,TimeCreated,Message | select -first 100 | fl | out-host -paging

Write-Host "Security Warnings:`n"
Get-WinEvent -filterhashtable @{'level'=3;'logname'='security'} -erroraction 'silentlycontinue' | select LogName,Id,TimeCreated,Message | select -first 100 | fl | out-host -paging

Read-Host "Done."