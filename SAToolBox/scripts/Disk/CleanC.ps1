Function Cleanup {
<#
.CREATED BY:
    Matthew A. Kerfoot
.CREATED ON:
    10\17\2013
.MODIFIED BY:
    Jeffrey E. Bryant
.MODIFIED ON:
    11\03\2017
.UPDATED ON:
    12\11\2017 to perserve WSUS update history
    11\03\2017
.UPDATED ON:
    03\23\2018 to remove other WER data
.Synopsis
   Aautomate cleaning up a C: drive with low disk space
.DESCRIPTION
   Cleans the C: drive's Window Temperary files, Windows SoftwareDistribution folder, `
   the local users Temperary folder, IIS logs(if applicable) and empties the recycling bin. `
   All deleted files will go into a log transcript in C:\Windows\Temp\. By default this `
   script leaves files that are newer than 7 days old however this variable can be edited.
.EXAMPLE
   PS C:\Users\mkerfoot\Desktop\Powershell> .\cleanup_log.ps1
   Save the file to your desktop with a .PS1 extention and run the file from an elavated PowerShell prompt.
.NOTES
   This script will typically clean up anywhere from 1GB up to 15GB of space from a C: drive.
.FUNCTIONALITY
   PowerShell v3
#>
function global:Write-Verbose ( [string]$Message )

# check $VerbosePreference variable, and turns -Verbose on
{ if ( $VerbosePreference -ne 'SilentlyContinue' )
{ Write-Host " $Message" -ForegroundColor 'Yellow' } }

$VerbosePreference = "Continue"
$DaysToDelete = 14
$LogDate = get-date -format "MM-d-yy-HH"
$objShell = New-Object -ComObject Shell.Application 
$objFolder = $objShell.Namespace(0xA)
$ErrorActionPreference = "silentlycontinue"
                    
Start-Transcript -Path C:\Windows\Temp\$LogDate.log

## Cleans all code off of the screen.
Clear-Host

$size = Get-ChildItem C:\Users\* -Include *.iso, *.vhd -Recurse -ErrorAction SilentlyContinue | 
Sort Length -Descending | 
Select-Object Name, Directory,
@{Name="Size (GB)";Expression={ "{0:N2}" -f ($_.Length / 1GB) }} |
Format-Table -AutoSize | Out-String

$Before = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName,
@{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } },
@{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}},
@{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } },
@{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } |
Format-Table -AutoSize | Out-String                      
                    
## Stops the windows update service. 
Get-Service -Name wuauserv | Stop-Service -Force -Verbose -ErrorAction SilentlyContinue
## Windows Update Service has been stopped successfully!

## Stops the Trusted Installer service. 
Get-Service -Name TrustedInstaller | Stop-Service -Force -Verbose -ErrorAction SilentlyContinue
## Trusted Installer Service has been stopped successfully!

## Deletes the contents of windows software distribution.
$exclude1 = @('*DataStore*')
Get-ChildItem "C:\Windows\SoftwareDistribution\" -exclude $exclude1 -Force -Verbose -ErrorAction SilentlyContinue |
Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete)) } |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The Contents of Windows SoftwareDistribution have been removed successfully!

## Deletes the contents of the Windows Temp folder.
Get-ChildItem "C:\Windows\Temp\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue |
Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete)) } |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The Ccontents of Windows Temp have been removed successfully!
             
## Deletes all files and folders in user's Temp folders. 
Get-ChildItem "C:\users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue |
Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The contents of C:\users\$env:USERNAME\AppData\Local\Temp\ have been removed successfully!

## Deletes all files and folders in the ESPS Reg Fix folder. 
Get-ChildItem "C:\Program Files (x86)\DISA\ESPS Windows Toolkit\HKU Reg Fix Files\*" -Recurse -Force -ErrorAction SilentlyContinue |
Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The contents of C:\Program Files (x86)\DISA\ESPS Windows Toolkit\HKU Reg Fix Files\ older than 7 days have been removed successfully!
                  
## Deletes all files and folders in the BladeLogic folder located on C. 
Get-ChildItem "C:\bladelogic\*" -Recurse -Force -ErrorAction SilentlyContinue |
Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The contents of C:\bladelogic\ folder have been removed successfully!

## Deletes all files and folders in the BladeLogic folder located on D. 
Get-ChildItem "D:\bladelogic\*" -Recurse -Force -ErrorAction SilentlyContinue |
Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The contents of D:\bladelogic\ folder have been removed successfully!

## Deletes the cbs.log files from the CBS Logs folder. 
Get-ChildItem "C:\Windows\Logs\CBS\cbs.log" -Recurse -Force -ErrorAction SilentlyContinue |
Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The C:\Windows\Logs\CBS\cbs.log file has been removed successfully!

## Deletes all files and folders in the temporary stage folder. 
Get-ChildItem "C:\tmp\stage\*" -Recurse -Force -ErrorAction SilentlyContinue |
Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The contents of C:\tmp\stage\ folder have been removed successfully!

## Deletes all files and folders in the $PatchCache$ folder. 
Get-ChildItem "c:\Windows\Installer\$PatchCache$\Managed\*" -Recurse -Force -ErrorAction SilentlyContinue |
Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The contents of c:\Windows\Installer\$PatchCache$\Managed\ folder have been removed successfully!

## Deletes all unneeded files from the  C:\Program Files\BMS Software\BladeLogic\RSCD\Transactions\ folder. 
$exclude2 = @('*log*','*locks*','*log*','*events*','*Database*','*analysis_archive*')
Get-ChildItem "C:\Program Files\BMC Software\BladeLogic\RSCD\Transactions\" -exclude $exclude2 -Force -ErrorAction SilentlyContinue |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The unnneded contents of C:\Program Files\BMS Software\BladeLogic\RSCD\Transactions\ folder have been removed successfully!

## Remove all files and folders in user's Windows Error Reporting (WER) folder.
## Per 2017 STIG update, we are no longer required to keep WER logs. 
Get-ChildItem "C:\users\*\AppData\Local\Microsoft\Windows\WER\" -Recurse -Force -Verbose -ErrorAction SilentlyContinue |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The contents of C:\users\$env:USERNAME\AppData\Local\Microsoft\Windows\WER\ have been removed successfully!  

## Remove all files and folders in ProgramData Windows Error Reporting (WER) folder.
## Per 2017 STIG update, we are no longer required to keep WER logs. 
Get-ChildItem "C:\ProgramData\Microsoft\Windows\WER\" -Recurse -Force -Verbose -ErrorAction SilentlyContinue |
remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
## The contents of C:\ProgramData\Microsoft\Windows\WER\ReportQueue have been removed successfully!                 
                  
## deletes the contents of the recycling Bin.
## The Recycling Bin is now being emptied!
$objFolder.items() | ForEach-Object { Remove-Item $_.path -ErrorAction Ignore -Force -Verbose -Recurse }
## The Recycling Bin has been emptied!

## Starts the Windows Update Service
##Get-Service -Name wuauserv | Start-Service -Verbose

## Starts the Trusted Installer Service
##Get-Service -Name TrustedInstaller | Start-Service -Verbose

$After =  Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object SystemName,
@{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } },
@{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}},
@{ Name = "FreeSpace (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } },
@{ Name = "PercentFree" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } |
Format-Table -AutoSize | Out-String

## Sends some before and after info for ticketing purposes

Hostname ; Get-Date | Select-Object DateTime
Write-Verbose "Before: $Before"
Write-Verbose "After: $After"
Write-Verbose $size
## Completed Successfully!
Stop-Transcript } Cleanup

read-host "Press Enter when Complete"