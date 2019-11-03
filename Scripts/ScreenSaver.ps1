$x = New-Object -ComObject "wscript.shell"; 
while ($true) {$x.Sendkeys("{NUMLOCK}"); Start-Sleep -Seconds 30;}
