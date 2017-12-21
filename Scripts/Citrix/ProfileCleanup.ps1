#========================================================================
# Generated By: Anders Wahlqvist
# Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
#========================================================================

$BaseProfilePath="C:\Users\"
$LocalProfileFolders=gci $BaseProfilePath
$thishost=hostname
$thishostADSI = [ADSI]"WinNT://$thishost,computer"  
$LocalAccountsOnThisHost=$thishostADSI.psbase.Children | Where-Object { $_.psbase.schemaclassname -eq 'user' } | % { $_.Name }
$ExcludedUsers= @()
$LoggedOnUsers = @()
$UsersToIgnore = @()

# Tune performance with $SpeedBrake. Lower is quicker, but uses more CPU.
$SpeedBrake=1

# Add a regex that works for your usernaming standard
$UserNameRegEx="\w"

# Add a list of other accounts you want to exclude
$ExcludedUsers="Public","ctx","svc","Ctx_StreamingSvc","Default","Default User","xadministrator","xadministrator.domain"

# This get's all the currently logged on users
$LoggedOnUsers=Get-WmiObject win32_process|select name,@{n="owner";e={$_.getowner().user}} | Select-Object Owner -Unique | % { $_.owner }

# Add them all togheter
$UsersToIgnore+=$LoggedOnUsers
$UsersToIgnore+=$ExcludedUsers
$UsersToIgnore+=$LocalAccountsOnThisHost
$UsersToIgnore=$UsersToIgnore | select -Unique

# Start to loop through all the profile folders
foreach ($LocalProfileFolder in $LocalProfileFolders)
{
    # Sleep to prevent CPU load
	sleep -m $SpeedBrake

    # Set this variable to True, it will be changed if it should stay later.
	$ThisProfileShouldBeDeleted=$True

    # This this folder match the username regex?
	if ($LocalProfileFolder.Name -match $UserNameRegEx)
	{
        # Make sure it doesn't match any of the "ignored" users, (logged on ones etc...)
		foreach ($UserToIgnore in $UsersToIgnore)
		{
        # Again, sleep to prevent CPU load.
		sleep -m $SpeedBrake
            # Check if it matches a "ignored" user
			if ($LocalProfileFolder.Name -like "*$UserToIgnore*")
			{
                # If it did, it should not be deleted.
			    $ThisProfileShouldBeDeleted=$False
			}

		}

        # Get the full path
		$CurrentProfileName=$LocalProfileFolder.FullName

        # Check if it should be deleted
		if ($ThisProfileShouldBeDeleted -eq $True)
		{
		    $ProfileToLookFor=$BaseProfilePath + $LocalProfileFolder.Name
		    $ProfileToClean=$ProfileToLookFor -replace "\\","\\"
		    $WMIQuery = $null
		    $WMIQuery=Get-WmiObject Win32_UserProfile  -computer '.' -filter "localpath='$ProfileToClean'"

			if ($WMIQuery -ne $null) {
    		        $TheProfileToDrop=$WMIQuery | Select-Object LocalPath
	                $WMIProfileToDrop=$TheProfileToDrop.LocalPath
	    	        Write-Output "Deleting $WMIProfileToDrop through WMI."
		            $WMIQuery.Delete()
			}
            else {
                cmd /c rd /s /q "$CurrentProfileName"
                Write-Output "No WMI-profile found, $CurrentProfileName folder was deleted though."
            }
        
    		Write-Output "$CurrentProfileName has been deleted."
		}

		else {
	    	Write-Output "$CurrentProfileName was skipped."
		}
	}
}
