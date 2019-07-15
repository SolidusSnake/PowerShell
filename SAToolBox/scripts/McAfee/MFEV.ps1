<#
Checks Registry for MFE. 
#>

function get-MFEversion {
	Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | select displayname, displayversion, publisher, installdate | where {$_.displayname -like "McAfee*"}

}


function get-VSEversion {
	Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | select displayname, displayversion, publisher, installdate | where {$_.displayname -like "McAfee*"}

}

function get-ePOList {
	Return ((Get-ItemProperty "HKLM:\Software\Network Associates\epolicy Orchestrator\Agent\" -Name ePoServerList).epoServerList -split "\|")[0]
}

function get-HipsException {
	return ((Get-item HKLM:\software\wow6432node\mcafee\hip\config\hipexception | select valuecount).valuecount -split "\ ")[0]
}

function get-APenabled {
	Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\McAfee\SystemCore\VSCore\On Access Scanner\BehaviourBlocking'
}

function get-OASstate {
	Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\McAfee\DesktopProtection'
}

function get-TagPolicy {
	Get-ItemProperty HKLM:\Software\Wow6432Node\McAfee\HIP\Config\Settings | Select Client_PolicyName_*
}

function get-6432ePolist {
    Return ((Get-ItemProperty "HKLM:\Software\wow6432node\Network Associates\epolicy Orchestrator\Agent\" -Name ePoServerList).epoServerList -split "\|")[0]
   }

clear-host


$MFEv = @()
$MFEv += get-VSEversion
$MFEv += get-MFEversion
$mapped_values = @{1="ENABLED";0="DISABLED"}
$mapped_values2 = @{3="ENABLED";1="DISABLED";2="DISABLED";4="DISABLED"}



Write-Host "`nProduct Versions:" -foregroundcolor green

$MFEv | Sort DisplayName | Select -Unique DisplayName,DisplayVersion | FT -Auto
write-Host "`n________________________________________________________________________________n"



Write-Host "`n
Tagged Policy: " -foregroundcolor green 

get-TagPolicy | FL

Write-Host "`n_______________________________________________________________________________`n"

Write-Host "`nManaging ePo: " -foregroundcolor green -nonewline;
if (Get-ItemProperty "HKLM:\Software\Network Associates\epolicy Orchestrator\Agent\" -ErrorAction SilentlyContinue) {
     
     $(get-ePoList)

} else {
    
     $(get-6432ePoList)

}


Write-Host "`nHips Exception Count: " -foregroundcolor green -nonewline; write-host $(get-hipsexception)

Write-host "`nAccess Protection: " -foregroundcolor green -nonewline; write-host $mapped_values[((get-APenabled -Name 'apenabled').apenabled)]

Write-host "`nOn Access Scanner: " -foregroundcolor green -nonewline; write-host $mapped_values2[((get-OASState -Name 'OASState').OASState)]











read-host "`nDone?"