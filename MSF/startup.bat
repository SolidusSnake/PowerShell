cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"
C:\Windows\SysWOW64\cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"
cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm quickconfig -transport:http
cmd.exe /c winrm set winrm/config @{MaxTimeoutms="1800000"}
cmd.exe /c winrm set winrm/config/winrs @{MaxMemoryPerShellMB="800"}
cmd.exe /c winrm set winrm/config/winrs @{MaxShellsPerUser="999"}
cmd.exe /c winrm set winrm/config/winrs @{MaxProcessesPerShell="999"}
cmd.exe /c winrm set winrm/config/service @{MaxConcurrentOperationsPerUser="999"}
cmd.exe /c winrm set winrm/config/service @{AllowUnencrypted="true"}
cmd.exe /c winrm set winrm/config/service/auth @{Basic="true"}
cmd.exe /c winrm set winrm/config/client/auth @{Basic="true"}
cmd.exe /c winrm set winrm/config/listener?Address=*+Transport=HTTP @{Port="5985"}
cmd.exe /c netsh advfirewall firewall set rule group="remote administration" new enable=yes
cmd.exe /c netsh firewall add portopening TCP 5985 "Port 5985"
cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm
%SystemRoot%\System32\reg.exe ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ /v HideFileExt /t REG_DWORD /d 0 /f
%SystemRoot%\System32\reg.exe ADD HKCU\Console /v QuickEdit /t REG_DWORD /d 1 /f
%SystemRoot%\System32\reg.exe ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ /v Start_ShowRun /t REG_DWORD /d 1 /f
%SystemRoot%\System32\reg.exe ADD HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ /v StartMenuAdminTools /t REG_DWORD /d 1 /f
%SystemRoot%\System32\reg.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\Power\ /v HibernateFileSizePercent /t REG_DWORD /d 0 /f
%SystemRoot%\System32\reg.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\Power\ /v HibernateEnabled /t REG_DWORD /d 0 /f
cmd.exe /c net user vagrant vagrant /add /y
cmd.exe /c net localgroup administrators vagrant /add
cmd.exe /c wmic useraccount where "name='vagrant'" set PasswordExpires=FALSE
cmd.exe /c mkdir -p C:\vagrant\scripts
cmd.exe /c C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File m:\install_dotnet45.ps1 -AutoStart
cmd.exe /c C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File m:\install_wmf.ps1 -AutoStart
cmd.exe /c C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File m:\openssh.ps1 -AutoStart
