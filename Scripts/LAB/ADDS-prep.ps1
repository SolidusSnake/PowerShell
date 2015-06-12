#Validate user is an Administrator
Write-Verbose "Checking Administrator credentials"
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You are not running this as an Administrator!`nRe-running script and will prompt for administrator credentials."
    Start-Process -Verb "Runas" -File PowerShell.exe -Argument "-STA -noprofile -file $($myinvocation.mycommand.definition)"
    Break
}

function Set-StaticIP()
{
    Write-Host "`nEnter IP address" -ForegroundColor Green
    $StaticIP = Read-Host ">"

    Write-Host "`nEnter subnet mask" -ForegroundColor Green
    $mask = Read-Host ">"

    Write-Host "`nEnter default gateway" -ForegroundColor Green
    $gateway = Read-Host ">"

    Write-Host "`nEnter primary DNS" -ForegroundColor Green
    $pDNS = Read-Host ">"

    Write-Host "`nEnter secondary DNS" -ForegroundColor Green
    $sDNS = Read-Host ">"

    $DNS = $pDNS,$sDNS

    $NetWMI = Get-WmiObject -ClassName Win32_NetworkAdapterConfiguration -Filter "ipenabled='true'";
    $NetWMI.EnableStatic("$StaticIP", "$mask");
    $NetWMI.SetGateways("$gateway", 1);
    $NetWMI.SetDNSServerSearchOrder("$DNS");
}

function Set-ComputerName()
{
    Write-Host "`nEnter new computer name" -ForegroundColor Green
    $newCN = Read-Host ">"

    Rename-Computer -NewName $newCN -Verbose
}

Write-Host "`nDid you set a static IP address? [Y/N]" -ForegroundColor Yellow
$step1 = Read-Host ">" 
if ($step1.ToUpper() -eq "N")
{
    Set-StaticIP
}

Clear-Host

Write-Host "`nDid you rename the lab computer? [Y/N]" -ForegroundColor Yellow
$step2 = Read-Host ">"
if ($step2.ToUpper() -eq "N")
{
    Set-ComputerName
}

Write-Host "`nDo you want to reboot now? [Y/N]" -ForegroundColor Yellow
$step3 = Read-Host ">"
if ($step3.ToUpper() -eq "Y")
{
    Write-Host "`nDCPROMO will continue after reboot" -ForegroundColor White -BackgroundColor Red
    $taskName = ('/TN {0}' -f '"Execute DCPROMO"')
    $startOn = ('/SC {0}' -f 'ONLOGON')
    $runAs = ('/RU {0}' -f '"NT AUTHORITY\SYSTEM"')
    $cmdExec = ('/TR {0}' -f '"powershell.exe -file C:\scripts\ADDS\phase-II\dcpromo.ps1"')
    $syntax = "schtasks.exe /create $taskName $startOn $runAs $cmdExec"

    Invoke-Expression $syntax

    Start-Sleep -Seconds 5
    Restart-Computer -Force -Verbose
}
