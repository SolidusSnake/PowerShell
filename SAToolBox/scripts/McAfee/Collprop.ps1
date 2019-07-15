<#
Collect and Send Props

Launch Agent Monitor

edited on: 7Nov2018 
#>



###################################### Collect and send Props ################################################


Write-Host "`nInitiating Collect and Send Props" -foregroundcolor green



sleep -s 3


& 'C:\Program Files\McAfee\Agent\cmdagent.exe' /p


##################################### Launch Agent Status Monitor ###########################################



Write-Host "`nLaunching Agent Status Monitor" -foregroundcolor green

sleep -s 5

& 'C:\Program Files\McAfee\Agent\cmdagent.exe' /s


#################################### Closing Agent Status Monitor  ############################################



read-host "`nPress enter when done"

Write-Host "`nclosing Agent Status Monitor" -foregroundcolor green

sleep -s 3

stop-process -name "UpdaterUI"

