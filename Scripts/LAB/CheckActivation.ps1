$licenseStatus=@{0="Unlicensed"; 1="Licensed"; 2="OOBGrace"; 3="OOTGrace"; 4="NonGenuineGrace"; 5="Notification"; 6="ExtendedGrace"}

$value=Get-CimInstance -Class SoftwareLicensingProduct | Where {$_.ApplicationID -eq "55c92734-d682-4d71-983e-d6ec3f16059f" -AND $_.PartialProductKey -ne $null}

$status =  $licenseStatus[[int]$value.LicenseStatus]

if ($status -ne "Licensed")
{
    & C:\scripts\activation\toolkit.exe
}

else
{
    "Licensed - $(Get-Date)" | Out-File C:\scripts\activation\status.txt -Force 
}
