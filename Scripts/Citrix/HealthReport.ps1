cls

################################################################################################
"Citrix XenApp Farm Health Check"
################################################################################################
# Original script:  https://www.czerno.com/Blog/post/2014/06/12/powershell-script-to-monitor-a-citrix-xenapp-farm-s-health

# Replaced: Session Reliability (SRPort) with disk free space (C$)
# Added: Primary disk free space (C$) check
# Added: Secure Gateway service check
# Modified: Various thresholds 

# This is script is based on Jason Poyner's XenApp Farm Health Report: http://deptive.co.nz/xenapp-farm-health-report/
# The original script emailed an HTML Report.
# I changed it to write to an HTML file and copy the file to a web server and only send 
# an email if there is a alert

# It must be ran from a XenApp Server.
# It requires the PowerShell SDK to be installed on the XenApp Server you run the script from.
# It requires a Web Server to copy the output file to.

# Powershell SDKs:
# XenApp 6.5 https://www.citrix.com/downloads/xenapp/sdks/powershell-sdk.html
# XenApp 5 http://blogs.citrix.com/2010/09/14/xenapp-5-powershell-sdk-tech-preview-3-released/

# I created two folders on my IIS web server, /Monitoring/XenApp65 and /Monitoring/XenApp5

######################################################################### 
############ USER VARIABLES, CHANGE TO MATCH YOUR ENVIRONMENT ###########
######################################################################### 

# Define the Load Evaluator to be checked in all the servers. 
# If you have more than one LE, define like ("TEST1","TEST2"). 
# This is optional, it is not required
$defaultLE = @("")

# Servers in the excluded folders will not be included in the health check. 
# This folder is with respect to the the server directory in Citrix console. 
# Example: @("Servers/Application", "Servers/Std Instances")
$excludedFolders = @("")

# Server to be excluded with any particular name or name filter. 
# Example: @("SRV1","SRV2")
$ServerFilter = @("")

# The maximum uptime days a server can report green. 
$maxUpTimeDays = 90

# Port numbers used for the functionality check. 
# Only change if you have modified the default port to a custom port.
$RDPPort = "3389"
$ICAPort = "1494"
$sessionReliabilityPort = "2598"

# Are you using Session reliability?
# Set this variable to True if using Session Reliability
$TestSessionReliabilityPort = "false"

# License Server Name for Citrix Farm to check the license usage.
$LicenseServer = "LIC_SRV"

# License Type to be defined [Eg: @("MPS_PLT_CCU", "MPS_ENT_CCU")]. 
# The license file can be in Enterprise or Platinum versions.
$LicenseTypes = @("MPS_ENT_CCU")

# E-mail reporting details. 
# If $emailFrom, $emailTo or $smtpServer are blank, no email will be sent.
# Define multiple email addresses like "email@domain.com,email2@domain.com"
$emailFrom     = "CitrixAlert@domain"
$emailTo       = "primary_team@mail"
$emailCC       = "user1@mail,user2@mail" # If no address to send CC leave the value as null
$smtpServer    = "SMTP_ADDR"

# How often to send mail if no new alerts are detected, in seconds
# If an existing alert still exists, it will not be sent again until
# this lag time is reached
$EmailAlertsLagTime = "900"

# Image Name of the image files in your script directory. 
# Keep the logo in the same directory as the script.
# This is the Logo used for the HTML Page
$ImageName1 = "citrix.png" 

# This is where the script will copy the HTML Page to
$HTMLServer = "D:\FarmMonitoring\"

# Enter the URL for the Monitoring Web Page
# This can be whatever web server you chose. I run IIS.
# The URL is included in the Alert Email
$MonitorURL = "https://website.mil/Citrix/XenApp/health.htm"

######################################################################### 
######################## END USER VARIABLES #############################
######################################################################### 

# Script Start Time
$script:startTime = Get-Date

# Reads the current directory path from the location of this file
$currentDir = Split-Path $MyInvocation.MyCommand.Path

#==================================================================================================
# Citrix Powershell snapin, Farm Name, Email Subject, Log files and headers used in the Main script
#==================================================================================================
# Define the Global variable and Check for the Citrix Snapin
# Checking whether the powershell snapins are available or not. Also check for any errors to load the snapin.
if ((Get-PSSnapin "Citrix.*" -EA silentlycontinue) -eq $null) {
	try { Add-PSSnapin Citrix.* -ErrorAction Stop }
	catch { write-error "Error loading XenApp Powershell snapin"; Return } }

# Get farm details once to use throughout the script
$FarmDetails = Get-XAFarm 
$CitrixFarmName = $FarmDetails.FarmName
$WebPageTitle = "$CitrixFarmName Health Status"

# Email Subject with the farm name
$emailSubject  = "Citrix Health Alert: (Citrix Farm: " + $CitrixFarmName + ")" 

# Log files are created in the location of script. 
$logfile = Join-Path $currentDir ("Citrix_Servers_HealthCheck.log")
$PreviuosLogFile = Join-Path $currentDir ("Citrix_Servers_HealthCheck_previuosrun.log")
$resultsHTM = Join-Path $currentDir ("Citrix_Servers_HealthCheck_Results.htm")
$AlertsEmailed = Join-Path $currentDir ("AlertsEmailed.log")
$CurrentAlerts = Join-Path $currentDir ("AlertsCurrent.log")
$AlertEmail = Join-Path $currentDir ("AlertsEmailTimeStamp.log")

if (Test-Path $logfile) { copy $logfile $PreviuosLogFile }

# The results are created as a table and its headers are formed using the below array. If there is any mismatch in this array it will not report correctly.
# If you want test any other functionalities, you may need to edit the table header as well as the main code of the script.
$headerNames  = "Ping", "Logons", "ActiveApps", "DiscUsers", "ServerLoad", "RDPPort", "ICAPort", "%Free(C:)", "AvgCPU", "MemUsg", "IMA", "CitrixPrint", "Spooler", "WMI", "RPC", "XML", "UptimeDays" 
$headerWidths = "6",    "6",      "6",           "6",         "6",          "4",       "4",       "4",      "5",      "5",     "6",    "6",           "8",       "8",   "6",   "8",   "8"

$ErrorStyle = "style=""background-color: #000000; color: #FF3300;"""
$WarningStyle = "style=""background-color: #000000;color: #FFFF00;"""

#==============================================================================================
# Functions used in the Main script
#==============================================================================================

#==============================================================================================
# This function will log the data / result into a logfile as well as in the powershell window. 
# The data is sent to function as parameter or a piped command output.
#==============================================================================================
Function LogMe() 
{
    Param( [parameter(Mandatory = $true, ValueFromPipeline = $true)] $logEntry,
	   [switch]$display,
	   [switch]$error,
	   [switch]$warning
	   #[switch]$progress
	   )
    if($error) { Write-Host "$logEntry" -Foregroundcolor Red; $logEntry = "[ERROR] $logEntry" }
	elseif($warning) { Write-Host "$logEntry" -Foregroundcolor Yellow; $logEntry = "[WARNING] $logEntry"}
	#elseif ($progress) { Write-Host "$logEntry" -Foregroundcolor Blue; $logEntry = "$logEntry" }
	elseif($display) { Write-Host "$logEntry" -Foregroundcolor Green; $logEntry = "$logEntry" }
    else { Write-Host "$logEntry"; $logEntry = "$logEntry" }

	$logEntry | Out-File $logFile -Append
}

#==============================================================================================
# This function will check the license usage report on the license server and will report the current usage
#==============================================================================================
Function CheckLicense() 
{
	if(!$LicenseServer) { "No License Server Name defined" | LogMe -Error; $LicenseResult = " Error; Check Detailed Logs "; return $LicenseResult }
	if(!$LicenseTypes) { "No License Type defined" | LogMe -Error; $LicenseResult = " Error; Check Detailed Logs "; return $LicenseResult }
	
	# Declare the variables to capture and calculate the License Usage
	[int]$TotalLicense = 0; [int]$InUseLicense = 0; [int]$PercentageLS = 0; $LicenseResult = " "
	
	# Error Handling if the server is not accessible for the license details or WMI issues
	Try 
	{   if(Get-Service -Display "Citrix Licensing" -ComputerName $LicenseServer -ErrorAction Stop) { "Citrix Licensing service is available." | LogMe -Display }
		else { "Citrix Licensing' service is NOT available." | LogMe -Error; Return "Error; Check Logs" }
		Try { 	if($licensePool = gwmi -class "Citrix_GT_License_Pool" -Namespace "ROOT\CitrixLicensing" -comp $LicenseServer -ErrorAction Stop) 
				{	"License Server WMI Class file found" | LogMe -Display 
					$LicensePool | ForEach-Object{ 
						foreach ($Ltype in $LicenseTypes)
						{   if ($_.PLD -match $Ltype) { $TotalLicense = $TotalLicense + $_.count; $InUseLicense = $InUseLicense + $_.InUseCount } } }
	
				"The total number of licenses available: $TotalLicense " | LogMe -Display
				"The number of licenses are in use: $InUseLicense " | LogMe -Display
				if(!(($InUseLicense -eq 0) -or ($TotalLicense -eq 0 ))) { $PercentageLS = (($InUseLicense / $TotalLicense ) * 100); $PercentageLS = "{0:N2}" -f $PercentageLS }
				
				if($PercentageLS -gt 90) { "The License usage is $PercentageLS % " | LogMe -Error }
				elseif($PercentageLS -gt 80) { "The License usage is $PercentageLS % " | LogMe -Warning }
				else { "The License usage is $PercentageLS % " | LogMe -Display }
	
				$LicenseResult = "$InUseLicense [ $PercentageLS % ]"; return $LicenseResult
			}
		} Catch { 
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                "License Server WMI Class file failed. An Error Occured while capturing the License information" | LogMe -Error
                "You may need to uninstall your License Server and reinstall." | LogMe -Error
                "There are known issues with doing an in place upgrade of the license service." | LogMe -Error
			    $LicenseResult = " Error; Check Detailed Logs "; return $LicenseResult }
	} Catch { "Error returned while checking the Licensing Service. Server may be down or some permission issue" | LogMe -error; return "Error; Check Detailed Logs" } 
}

#==============================================================================================
# This function will check the service using its display name. 
# If the service is not found, returns a value as N/A. 
# If service is not started, then it will start the service.
#==============================================================================================
Function CheckService() 
{   
	Param ($ServiceName)
	Try 
	{   if (!(Get-Service -Display $ServiceName -ComputerName $server -ErrorAction SilentlyContinue) ) { "$ServiceName is not available..." | LogMe -display; $ServiceResult = "N/A" }
    	else {
        	if ((Get-Service -Display $ServiceName -ComputerName $server -ErrorAction Stop).Status -Match "Running") { "$ServiceName is running" | LogMe -Display; $ServiceResult = "Success" }
        	else { "$ServiceName is not running"  | LogMe -error
				Try { Start-Service -InputObject $(Get-Service -Display $ServiceName -ComputerName $server) -ErrorAction Stop 
					"Start command sent for $ServiceName"  | LogMe -warning
            		Start-Sleep 5 # Sleep a bit to allow service to start
					if ((Get-Service -Display $ServiceName -ComputerName $server).Status -Match "Running") { "$ServiceName is now running" | LogMe -Display; $ServiceResult = "Success" }
					else {	"$ServiceName failed to start."  | LogMe -error	$ServiceResult = "Error" }
				} Catch { "Start command failed for $ServiceName. You need to check the server." | LogMe -Error; return "Error" } } }
    	return $ServiceResult
	} Catch { "Error while checking the Service. Server may be down or has a permission issue." | LogMe -error; return "Error" } 
}

#==============================================================================================
# This function will check the processor counter and check for the CPU usage. 
# Takes an average CPU usage for 5 seconds.
#==============================================================================================
Function CheckCpuUsage() 
{ 
	param ($hostname)
	Try { $CpuUsage=(get-counter -ComputerName $hostname -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5 -ErrorAction Stop | select -ExpandProperty countersamples | select -ExpandProperty cookedvalue | Measure-Object -Average).average
    	$CpuUsage = "{0:N1}" -f $CpuUsage; return $CpuUsage
	} Catch { "Error returned while checking the CPU usage. Perfmon Counters may be at fault." | LogMe -error; return 101 } 
}

#==============================================================================================
# This function will check the primary disk free space. 
#==============================================================================================
Function CheckDriveSpace()
{ 
	param ($hostname)
	Try { $OSFreeSpace=(get-counter -ComputerName $hostname -Counter "\LogicalDisk(C:)\% Free Space" -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop | select -ExpandProperty countersamples | select -ExpandProperty cookedvalue)
    	$OSFreeSpace = "{0:N1}" -f $OSFreeSpace; return $OSFreeSpace
	} Catch { "Error returned while checking the drive free space. Perfmon Counters may be at fault." | LogMe -error; return 101 } 
}

#============================================================================================== 
# This function check the memory usage and report the usage value in percentage
#==============================================================================================
Function CheckMemoryUsage() 
{ 
	param ($hostname)
    Try 
	{   $SystemInfo = (Get-WmiObject -computername $hostname -Class Win32_OperatingSystem -ErrorAction Stop | Select-Object TotalVisibleMemorySize, FreePhysicalMemory)
    	$TotalRAM = $SystemInfo.TotalVisibleMemorySize/1MB 
    	$FreeRAM = $SystemInfo.FreePhysicalMemory/1MB 
    	$UsedRAM = $TotalRAM - $FreeRAM 
    	$RAMPercentUsed = ($UsedRAM / $TotalRAM) * 100 
    	$RAMPercentUsed = "{0:N2}" -f $RAMPercentUsed
    	return $RAMPercentUsed
	} Catch { "Error returned while checking the Memory usage. Perfmon Counters may be at fault" | LogMe -error; return 101 } 
}

#==============================================================================================
# This function will check the ping response to the server and report any failures
#==============================================================================================
Function Ping ([string]$hostname, [int]$timeout) 
{
    $ping = new-object System.Net.NetworkInformation.Ping #creates a ping object
	try { $result = $ping.send($hostname, $timeout).Status.ToString() }
    catch { $result = "Failed" }
	return $result
}

#==============================================================================================
# The function check the response from the port like a telnet query. 
# If ICA port, then it check for the ICA response too 
#==============================================================================================
Function Check-Port() 
{ 
	param ([string]$hostname, [string]$port)
    try { $socket = new-object System.Net.Sockets.TcpClient($hostname, $Port) -ErrorAction Stop } #creates a socket connection to see if the port is open
    catch { $socket = $null; "Socket connection on $port failed" | LogMe -error; return $false }

	if($socket -ne $null) { "Socket Connection on $port Successful" | LogMe -Display
        if($port -eq "1494") {
            $stream   = $socket.GetStream() #gets the output of the response
			$buffer   = new-object System.Byte[] 1024
			$encoding = new-object System.Text.AsciiEncoding
			Start-Sleep -Milliseconds 500 #records data for half a second			
			while($stream.DataAvailable) {
                $read     = $stream.Read($buffer, 0, 1024)  
				$response = $encoding.GetString($buffer, 0, $read)
				#Write-Host "Response: " + $response
				if($response -like '*ICA*'){ "ICA protocol responded" | LogMe -Display; return $true } 
			}
			"ICA did not respond correctly" | LogMe -error; return $false } else { return $true }
	} else { "Socket connection on $port failed" | LogMe -error; return $false }
}

#==============================================================================================
# HTML Formating
#==============================================================================================
Function writeHtmlHeader 
{ 
	param($title, $fileName)
	
    $date = ( Get-Date -format g)
    $head = @"
    <html>
    <head>
    <meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>
    <meta http-equiv="refresh" content="120">
    <title>$title</title>
    <STYLE TYPE="text/css">
    <!--
    td {
        font-family: Lao UI;
        font-size: 11px;
        border-top: 1px solid #999999;
        border-right: 1px solid #999999;
        border-bottom: 1px solid #999999;
        border-left: 1px solid #999999;
        padding-top: 0px;
        padding-right: 0px;
        padding-bottom: 0px;
        padding-left: 0px;
        overflow: hidden;}

    .header {
	    font-family: Tahoma;
		font-size: 40px;
		font-weight:bold;
		border-top: 1px solid #999999;
		border-right: 1px solid #999999;
		border-bottom: 1px solid #999999;
		border-left: 1px solid #999999;
		padding-top: 0px;
		padding-right: 0px;
		padding-bottom: 0px;
		padding-left: 0px;
        overflow: hidden;
		color:#FFFFFF;
		text-shadow:2px 2px 10px #000000;

        }
    body {
        margin-left: 5px;
        margin-top: 5px;
        margin-right: 0px;
        margin-bottom: 10px;
        table {
            table-layout:fixed;
            border: thin solid #FFFFFF;}
	.shadow {
		height: 1em;
		filter: Glow(Color=#000000,
		Direction=135,
		Strength=5);}
        -->
    </style>
    </head>
    <body bgcolor='#323232'>
        <table class="header" width='100%'>
        <tr bgcolor='#323232'>
        <td style="text-align: center; text-shadow: 2px 2px 2px #ff0000;">
        <img src="$ImageName1">
        </td>
        <td class="header" width='826' align='center' valign="middle" style="background-image: url('ekg_wide.jpg'); background-repeat: no-repeat; background-position: center; ">
        <p class="shadow"> Citrix Farm: $CitrixFarmName<br>Health Status </p>
        </tr>
        </table>
        <table width='100%'>
        <tr bgcolor='#CCCCCC'>
        <td width=33% align='center' valign="middle">
        <font face='Tahoma' color='#8A0808' size='2'><strong>Farm Last Queried: $date</strong></font>
        </td>
        <td width=33% align='center' valign="middle">
        <font face='Tahoma' color='#8A0808' size='2'>
        <strong>Page Last Refresfed: 
        <script type="text/javascript">
        <!--
        var currentTime = new Date()
        var month = currentTime.getMonth() + 1
        var day = currentTime.getDate()
        var year = currentTime.getFullYear()
        var hours = currentTime.getHours()
        var minutes = currentTime.getMinutes()
        if (minutes < 10){
        minutes = "0" + minutes
        }
        document.write(month + "/" + day + "/" + year + " " + hours + ":" + minutes + " ")
        if(hours > 11){
        document.write("PM")
        } else {
        document.write("AM")
        }
        //-->
        </script>
        </strong>
        </td>
        <td width=33% align='center' valign="middle">
        <font face='Tahoma' color='#8A0808' size='2'>
        <strong>Auto-Refresh in <span id="CDTimer">180</span> secs.</font></strong>
        <script language="JavaScript" type="text/javascript">
        /*<![CDATA[*/
        var TimerVal = 120;
        var TimerSPan = document.getElementById("CDTimer");
        function CountDown(){
        setTimeout( "CountDown()", 1000 );
        TimerSPan.innerHTML=TimerVal;
        TimerVal=TimerVal-1;
        } CountDown() /*]]>*/ </script>
        </td>
        </tr>
        </table>
        <table width='100%'>
        <tr bgcolor='#CCCCCC'>
        <td width=50% align='center' valign="middle">
        <font face='Tahoma' color='#003399' size='2'><strong>Number of Servers in the farm: $TotalServersCount</strong></font>
        <td width=50% align='center' valign="middle">
        <font face='tahoma' color='#003399' size='2'><strong>Citrix License Usage:  $LicenseReport</strong></font>
        </td>
        </tr>
        </table>
        <table width='100%'>
        <tr bgcolor='#CCCCCC'>
        <td width=50% align='center' valign="middle">
        <font face='Tahoma' color='#003399' size='2'><strong>Active Applications:  $TotalActiveSessions</strong></font>
        <td width=50% align='center' valign="middle">
        <font face='tahoma' color='#003399' size='2'><strong>Disconnected Sessions:  $TotalDisconnectedSessions</strong></font>
        </td>
        </tr>
        </table>
"@
    $head | Out-File $fileName
}

# ==============================================================================================
# Write Table Header
# ==============================================================================================
Function writeTableHeader 
{ 
	param($fileName)
	
    $tableHeader = @"
    <table width='100%'><tbody>
    <tr bgcolor=#CCCCCC>
    <td width='12%' align='center'><strong>ServerName</strong></td>
"@

    $i = 0
    while ($i -lt $headerNames.count) {
        $headerName = $headerNames[$i]
        $headerWidth = $headerWidths[$i]
        #$tableHeader += "<td width='" + $headerWidth + "%' align='center'><strong>$headerName</strong></td>"
        $tableHeader += "<td align='center'><strong>$headerName</strong></td>"
        $i++ }

    $tableHeader += "</tr>"
    $tableHeader | Out-File $fileName -append 
}

# ==============================================================================================
# Write Data
# ==============================================================================================
Function writeData 
{   
	param($data, $fileName)
	
	$data.Keys | sort | foreach {
		$tableEntry += "<tr>"
		$computerName = $_
		$tableEntry += ("<td bgcolor='#CCCCCC' align=center><font color='#003399'><b>$computerName</b></font></td>")
		#$data.$_.Keys | foreach {
		$headerNames | foreach {
			#"$computerName : $_" | LogMe -display
			try {
				if ($data.$computerName.$_[1] -eq $null ) { $bgcolor = "#FF0000"; $fontColor = "#FFFFFF"; $testResult = "Err" }
				else {
					if ($data.$computerName.$_[0] -eq "SUCCESS") { $bgcolor = "#387C44"; $fontColor = "#FFFFFF" }
					elseif ($data.$computerName.$_[0] -eq "WARNING") { $bgcolor = "#F5DA81"; $fontColor = "#000000" }
					elseif ($data.$computerName.$_[0] -eq "ERROR") { $bgcolor = "#FF0000"; $fontColor = "#000000" }
					else { $bgcolor = "#CCCCCC"; $fontColor = "#003399" }
					$testResult = $data.$computerName.$_[1]
				} } catch { $bgcolor = "#CCCCCC"; $fontColor = "#003399"; $testResult = "N/A" }
			$tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'>$testResult</font></td>")
		}
		$tableEntry += "</tr>"
	}
	$tableEntry | Out-File $fileName -append
}

# ==============================================================================================
# Echo Errors and Warnings and prepare for email
# ==============================================================================================
Function echoData 
{   
	param($data)
    $data.Keys | sort | foreach {
    $computerName = $_
    $headerNames | foreach {
    try {
            if ($data.$computerName.$_[1] -eq $null ) { $testResult = "Err" }
            else {
                    if ($data.$computerName.$_[0] -eq "SUCCESS") { }
                    elseif ($data.$computerName.$_[0] -eq "WARNING") 
                        { 
                        $warnserver = $computerName 
                        $warnvalue = $data.$computerName.$_[1] | out-string
                        $warncomp = $_
                        $script:EchoWarnings += "Server Name: $warnserver, Component: $warncomp, Value: $warnvalue"
                        $script:Warnings += "<p $WarningStyle>Server Name: <strong>$warnserver</strong><br>Component: <strong>$warncomp</strong><br>Value: <strong>$warnvalue</strong></p>"
                        }
                    elseif ($data.$computerName.$_[0] -eq "ERROR") 
                        { 
                        $errserver = $computerName
                        $errvalue = $data.$computerName.$_[1] | out-string
                        $errcomp = $_
                        $script:EchoErrors +="Server Name: $errserver, Component: $errcomp, Value: $errvalue"
                        $script:Errors += "<p $ErrorStyle>Server Name: <strong>$errserver</strong><br> Component: <strong>$errcomp</strong><br> Value: <strong>$errvalue</strong></p>"
                        }
                    else { }
					$testResult = $data.$computerName.$_[1]
				} } 
                catch { $testResult = "N/A" }
		}
	}
}
 
# ==============================================================================================
# Write HTML Footer
# ==============================================================================================
Function writeHtmlFooter { 
	param($fileName)
$footer=("<br><font face='HP Simplified' color='#ffffff' size='3'><br><I><b>Secure Gateway - 01: {5}<br>Secure Gateway - 02: {6}<br><br>Report last updated on {0}</font>" -f (Get-Date -displayhint date),$env:userdomain,$env:username,$env:COMPUTERNAME,$currentDir,((Get-Service -ComputerName SGW_01 CtxSecGwy).Status),((Get-Service -ComputerName SGW_02 CtxSecGwy).Status))#,$global:auBGcolor,$global:avBGcolor
@"
</table>
</body>
</html>
"@ | Out-File $FileName -append
$footer | Out-File $FileName -append

}

# ==============================================================================================
# Script Time Elapsed Function
# ==============================================================================================
function GetElapsedTime([datetime]$starttime) 
{
    $runtime = $(get-date) - $starttime
    $retStr = [string]::format("{0} sec(s)", $runtime.TotalSeconds)
    $retStr
}

#==============================================================================================
#                       END Functions used in the script
#==============================================================================================

#==============================================================================================
#============                                                                    ==============
#============                        MAIN SCRIPT STARTS HERE                     ==============
#============                                                                    ==============
#==============================================================================================

rm $logfile -force -EA SilentlyContinue

"Script Started at $script:startTime" | LogMe -display 
" " | LogMe -display
" " | LogMe -display

# The variable to count the server names
[int]$TotalServers = 0; $TotalServersCount = 0

# Calling the license checking function here
"Checking Citrix License usage on $LicenseServer" | LogMe -Display 
$LicenseReport = CheckLicense

# Starting the server health check with a notification title
" " | LogMe; "Checking Citrix XenApp Server Health." | LogMe ; " " | LogMe

$allResults = @{}




# Get all user sessions list once to use throughout the script
$sessions = Get-XASession
 
    #======================================================================================
    #                   PULL THE SERVER NAMES FROM THE FARM COLLECTIONS
    #======================================================================================  
    Get-XAServer | % { $tests = @{}	
	# Check to see if the server is in an excluded folder path or server list
    if($excludedFolders -contains $_.FolderPath) { $_.ServerName + " in excluded Server folder - skipping" | LogMe -Display; "" | LogMe; return }
	if($ServerFilter -contains $_.ServerName) { $_.ServerName + " is excluded in the Server List  - skipping" | LogMe -Display; "" | LogMe; return }
	# Just displaying the server serial number and the server name
    [int]$TotalServers = [int]$TotalServers + 1; $server = $_.ServerName
	"Server Name: $server" | LogMe

        #======================================================================================
        #                   CHECK SERVER AVAILABILITY USING PING and LOGON STATUS
        #======================================================================================
        # Ping server 
        $result = Ping $server 1000
        if($result -ne "SUCCESS") 
            { 
            # If ping failed, then it will notify and skips the rest of the checks.
            $tests.Ping = "ERROR", $result; "NOT able to ping - skipping " | LogMe -error 
            }
        else 
            {   
            $tests.Ping = "SUCCESS", $result;  "Server is responding to ping" | LogMe -Display
                # Check server logons
                if($_.LogOnsEnabled -eq $false) { "Logons are disabled " | LogMe -error; $tests.Logons = "ERROR", "Disabled" } 
                else { "Logons are enabled " | LogMe -Display; $tests.Logons = "SUCCESS","Enabled" }
	
        #====================================================================================
        #                 CHECK ACTIVE AND DISCONNECTED USER SESSIONS
        #====================================================================================
    	# Report on active server sessions
    	$activeServerSessions = [array]($sessions | ? {$_.State -eq "Active" -and $_.Protocol -eq "Ica" -and $_.ServerName -match $server})
    	if($activeServerSessions) { $totalActiveServerSessions = $activeServerSessions.count }
    	else { $totalActiveServerSessions = 0 }
        $tests.ActiveApps = "SUCCESS", $totalActiveServerSessions 
        "Active ICA sessions: $totalActiveServerSessions" | LogMe -display
        
        # Report on disconnected server sessions
    	$discServerSessions = [array]($sessions | ? {$_.State -eq "Disconnected" -and $_.Protocol -eq "Ica" -and $_.ServerName -match $server})
    	if($discServerSessions) { $totalDiscServerSessions = $discServerSessions.count } 
    	else { $totalDiscServerSessions = 0 }
        $tests.DiscUsers = "SUCCESS", $totalDiscServerSessions 
        "Disconnected ICA sessions: $totalDiscServerSessions" | LogMe -display
        
        # Creates a warning if both active and disconnected sessions are zero
        # This will create a false positive when a session is RDP
        # Great for testing, but remarked when not testing
        #if(($totalActiveServerSessions -eq 0) -and ($totalDiscServerSessions -eq 0))
        #    {
        #    $tests.ActiveApps = "WARNING", $totalActiveServerSessions
        #    $tests.DiscUsers = "WARNING", $totalDiscServerSessions
        #    }

        #=============================================================================================
        #                   CHECK CITRIX LOAD EVALUATOR NAME
        #=============================================================================================
    	# Check Load Evaluator
		$LEFlag = 0; $CurrentLE = ""
		$CurrentLE = (Get-XALoadEvaluator -ServerName $server).LoadEvaluatorName
		foreach ($LElist in $defaultLE) {
            if($CurrentLE -match $LElist) {    
                "Default Load Evaluator assigned" | LogMe -display
                $tests.LoadEvaluator = "SUCCESS", $CurrentLE
                $LEFlag = 1; break } }
        if($LEFlag -eq 0 ) {
            if($CurrentLE -match "Offline") {
				"Server is in Offline LE; Please check the box" | LogMe -error
				$tests.LoadEvaluator = "ERROR", $CurrentLE }
			else {
				"Non-default Load Evaluator assigned" | LogMe -warning
            	$tests.LoadEvaluator = "WARNING", $CurrentLE } }
		
        #==============================================================================================
        #                   CHECK PORT CONNECTIVITY
        #==============================================================================================
		# Test RDP connectivity
		if(Check-Port $server $RDPPort) { $tests.RDPPort = "SUCCESS", "Success" }
		else { $tests.RDPPort = "ERROR", "No response" }        

		# Test ICA connectivity
		if (Check-Port $server $ICAPort) { $tests.ICAPort = "SUCCESS", "Success" }
		else { $tests.ICAPort = "ERROR","No response" }
                
        if ($TestSessionReliabilityPort -eq "True")
            {
                # Test Session Reliability port
                if (Check-Port $server $sessionReliabilityPort) { $tests.SRPort = "SUCCESS", "Success" }
                else { $tests.SRPort = "ERROR", "No response" }
            }
        
        #==============================================================================================
        #               CHECK CPU AND MEMORY USAGE 
        #==============================================================================================
        # Check the AvgCPU value for 5 seconds
        $AvgCPUval = CheckCpuUsage ($server)
        if( [int] $AvgCPUval -lt 80) { "CPU usage is normal [ $AvgCPUval % ]" | LogMe -display; $tests.AvgCPU = "SUCCESS", ($AvgCPUval) }
		elseif([int] $AvgCPUval -lt 90) { "CPU usage is medium [ $AvgCPUval % ]" | LogMe -warning; $tests.AvgCPU = "WARNING", ($AvgCPUval) }   	
		elseif([int] $AvgCPUval -lt 95) { "CPU usage is high [ $AvgCPUval % ]" | LogMe -error; $tests.AvgCPU = "ERROR", ($AvgCPUval) }
		elseif([int] $AvgCPUval -eq 101) { "CPU usage test failed" | LogMe -error; $tests.AvgCPU = "ERROR", "Err" }
        else { "CPU usage is Critical [ $AvgCPUval % ]" | LogMe -error; $tests.AvgCPU = "ERROR", ($AvgCPUval) }   
		$AvgCPUval = 0
 
        # Check the Physical Memory usage       
        $UsedMemory = CheckMemoryUsage ($server)
        if( [int] $UsedMemory -lt 80) { "Memory usage is normal [ $UsedMemory % ]" | LogMe -display; $tests.MemUsg = "SUCCESS", ($UsedMemory) }
		elseif([int] $UsedMemory -lt 85) { "Memory usage is medium [ $UsedMemory % ]" | LogMe -warning; $tests.MemUsg = "WARNING", ($UsedMemory) }   	
		elseif([int] $UsedMemory -lt 90) { "Memory usage is high [ $UsedMemory % ]" | LogMe -error; $tests.MemUsg = "ERROR", ($UsedMemory) }
		elseif([int] $UsedMemory -eq 101) { "Memory usage test failed" | LogMe -error; $tests.MemUsg = "ERROR", "Err" }
        else { "Memory usage is Critical [ $UsedMemory % ]" | LogMe -error; $tests.MemUsg = "ERROR", ($UsedMemory) }   
		$UsedMemory = 0 

        #==============================================================================================
        #               CHECK OS DRIVE FREE SPACE 
        #==============================================================================================
        $usedStorage = CheckDriveSpace ($server)
        if( [int] $usedStorage -le 5) { "Disk usage is high [ $usedStorage % ]" | LogMe -display; $tests."%Free(C:)" = "ERROR", ($usedStorage) }
        elseif( [int] $usedStorage -le 10) { "Disk usage is medium [ $usedStorage % ]" | LogMe -display; $tests."%Free(C:)" = "WARNING", ($usedStorage) }
        else  { "Disk usage is normal [ $usedStorage % ]" | LogMe -display; $tests."%Free(C:)" = "SUCCESS", ($usedStorage) }
        $usedStorage = 0

        #===========================================================================================
        #                  CHECK SERVICES STATUS 
        #===========================================================================================
		# Check services using its display name
        $ServiceOP = CheckService ("Citrix Independent Management Architecture")
        if ($ServiceOP -eq "Error")  { $tests.IMA = "ERROR", $ServiceOP }
        else { $tests.IMA = "SUCCESS", $ServiceOP }

        $ServiceOP = CheckService ("Print Spooler")
        if ($ServiceOP -eq "Error")  { $tests.Spooler = "ERROR", $ServiceOP }
        else { $tests.Spooler = "SUCCESS", $ServiceOP }

        $ServiceOP = CheckService ("Citrix Print Manager Service")
        if ($ServiceOP -eq "Error")  { $tests.CitrixPrint = "ERROR", $ServiceOP }
        else { $tests.CitrixPrint = "SUCCESS", $ServiceOP }
		
		$ServiceOP = CheckService ("Citrix XML Service")
        if ($ServiceOP -eq "Error")  { $tests.XML = "ERROR", $ServiceOP }
        else { $tests.XML = "SUCCESS", $ServiceOP }

        #===========================================================================================
        #                   CHECK CITRIX LOAD, WMI, Server Uptime and RPC
        #===========================================================================================
		# If the IMA service is running, check the server load
		if ($tests.IMA[0] -eq "Success") {
            $CurrentServerLoad = Get-XAServerLoad -ServerName $server
			if([int] $CurrentServerLoad.load -lt 7500) { 
				If([int] $CurrentServerLoad.load -eq 0) { $tests.ActiveApps = "SUCCESS", $totalActiveServerSessions; $tests.DiscUsers = "SUCCESS", $totalDiscServerSessions }
				"Serverload is normal : $CurrentServerload" | LogMe -display; $tests.Serverload = "SUCCESS", ($CurrentServerload.load) }
			elseif([int] $CurrentServerLoad.load -lt 8500) { "Serverload is Medium : $CurrentServerload" | LogMe -warning; $tests.Serverload = "WARNING", ($CurrentServerload.load) }
			elseif([int] $CurrentServerLoad.load -eq 20000) { "Serverload fault : could not contact License server" | LogMe -Error; $tests.Serverload = "ERROR", "LS Err" }    
			elseif([int] $CurrentServerLoad.load -eq 99999) { "Serverload fault : No load evaluator is configured" | LogMe -Error; $tests.Serverload = "ERROR", "No LE" }
			elseif([int] $CurrentServerLoad.load -eq 10000) { "Serverload is full : $CurrentServerload" | LogMe -Error; $tests.Serverload = "ERROR", ($CurrentServerload.load) }
			else { "Serverload is High : $CurrentServerload" | LogMe -error; $tests.Serverload = "ERROR", ($CurrentServerload.load) }   
			$CurrentServerLoad = 0 }
        else { "Server load can't be determine since IMA failed " | LogMe -error; $tests.Serverload = "ERROR", "IMA Err" }

		# Test WMI
		$tests.WMI = "ERROR","Error"
		try { $wmi=Get-WmiObject -class Win32_OperatingSystem -computer $_.ServerName } 
		catch {	$wmi = $null }
		
        # Perform WMI related checks
		if ($wmi -ne $null) {
			$tests.WMI = "SUCCESS", "Success"; "WMI connection success" | LogMe -display
			$LBTime=$wmi.ConvertToDateTime($wmi.Lastbootuptime)
			[TimeSpan]$uptime=New-TimeSpan $LBTime $(get-date)

			if ($uptime.days -gt $maxUpTimeDays) { "Server reboot warning, last reboot: {0:D}" -f $LBTime | LogMe -warning; $tests.UptimeDays = "WARNING", $uptime.days } 
            else { "Server uptime days: $uptime" | LogMe -display; $tests.UptimeDays = "SUCCESS", $uptime.days } } 
        else { "WMI connection failed - check WMI for corruption" | LogMe -error }
        
        #Check RPC
        if (Test-Connection -ComputerName $server -Quiet -Count 1)
            {
                if (Get-WmiObject win32_computersystem -ComputerName $server -ErrorAction SilentlyContinue)
                    { $tests.RPC = "SUCCESS", "Success"; "RPC responded" | LogMe -Display  }
                else { $tests.RPC = "ERROR", "No response from RPC"; "RPC failed" | LogMe -error }
            }
        else { $tests.RPC = "ERROR", "No response from RPC"; "RPC failed" | LogMe -error }
	}
	$allResults.$server = $tests
    " " | LogMe -display
}

$gateways = "SGW_01","SGW_02"

$gateways | ForEach-Object { $test2 = @{}

	$server = $_
	
	"Server Name: $server" | LogMe

	$ServiceOP = CheckService ("Citrix Secure Gateway")
	if ($ServiceOP -eq "ERROR") {$test2.SGW = "ERROR", $ServiceOP }
	else { $test2.SGW = "Success", $ServiceOP }
	
	#$allResults.$server = $test2
	" " | LogMe -display
}

#===========================================================================================
#                                    DISPLAY TOTALS
#===========================================================================================
$TotalServersCount = [int]$TotalServers

$ActiveApps = [array]($sessions | ? {$_.State -eq "Active" -and $_.Protocol -eq "Ica"})
$DiscUsers = [array]($sessions | ? {$_.State -eq "Disconnected" -and $_.Protocol -eq "Ica"})

if($ActiveApps) { $TotalActiveSessions = $ActiveApps.count } else { $TotalActiveSessions = 0 }
if($DiscUsers) { $TotalDisconnectedSessions = $DiscUsers.count } else { $TotalDisconnectedSessions = 0 }

"Total Number of Servers: $TotalServersCount" | LogMe 
"Total Active Applications: $TotalActiveSessions" | LogMe 
"Total Disconnected Sessions: $TotalDisconnectedSessions" | LogMe 

" " | LogMe -display

#===========================================================================================
#            SAVING REPORT TO HTML FILE AND COPYING TO WEB SERVER
#===========================================================================================
# Write all results to an html file
("Saving results to html report: " + $resultsHTM) | LogMe 
# Merging all the Header, Body and Footer of the HTML
writeHtmlHeader $WebPageTitle $resultsHTM
writeTableHeader $resultsHTM
$allResults | sort-object -property FolderPath | % { writeData $allResults $resultsHTM }
writeHtmlFooter $resultsHTM

# Copying files to Web Server
("Copying $resultsHTM to: " + $HTMLServer +"\health.htm") | LogMe 
try {copy-item $resultsHTM $HTMLServer\health.htm}
catch { "Error Copying $resultsHTM to $HTMLServer\health.htm" | LogMe -error
        $_.Exception.Message | LogMe -error}

("Copying $currentDir\$ImageName1 to: " + $HTMLServer) | LogMe 
try {copy-item "$currentDir\$ImageName1" $HTMLServer}
catch { "Error Copying $currentDir\$ImageName1 to $HTMLServer" | LogMe -error
        $_.Exception.Message | LogMe -error}

#("Copying $currentDir\ekg_wide.jpg to: " + $HTMLServer) | LogMe 
#try {copy-item "$currentDir\ekg_wide.jpg" $HTMLServer}
#catch { "Error Copying $currentDir\ekg_wide.jpg to $HTMLServer" | LogMe -error
#        $_.Exception.Message | LogMe -error}

#===========================================================================================
#                   CHECKING FOR WARNINGS AND ERRORS
#===========================================================================================
# Echo Errors and Warnings and preparing for email
echoData $allResults

# Display Errors or Warnings
# Set variable to be used later

    if (!$script:Warnings)
        { " " | LogMe -display
        "No Warnings detected" | LogMe -display
        $WarningsDetected = $False 
        }
    else 
        { " " | LogMe -display
        "Warnings Detected:" | LogMe 
        foreach ($line in $script:EchoWarnings){$line | LogMe -warning}
         $WarningsHeader = "<p><strong>WARNINGS Detected:</strong></p>"
         $WarningsDetected = $True
        }

    if (!$script:Errors) 
        {  
        " " | LogMe -display
        "No Errors detected" | LogMe -display
        $ErrorsDetected = $False
        }
    else 
        { " " | LogMe -display
        "Errors Detected:" | LogMe 
        foreach ($line in $script:EchoErrors) {$line | LogMe -error} 
        $ErrorsHeader = "<p><strong>ERRORS Detected:</strong></p>"
        $ErrorsDetected = $True
        }

# Get the Current Time for Email Alert Time Stamp
$CurrTime = Get-Date -format g

# Checking to see if there were any Warnings or Errors Detected
# If there were, update the CurrentAlerts Log File for later comparison
if (($WarningsDetected -eq $True) -or ($ErrorsDetected -eq $True)) 
    {
    $ErrorsandWarnings = $script:EchoWarnings,$script:EchoErrors
    if (Test-Path $CurrentAlerts) { clear-content $CurrentAlerts }
    foreach ($line in $ErrorsandWarnings) {$Line | Add-Content $CurrentAlerts}
            
        # Get Content from Alert Log File, we want the first line, which should be the previuos time stamp.
        if (Test-Path $AlertEmail) 
            { $AlertFileTime = gc $AlertEmail -TotalCount 1 } 

        # Check to see if the Time Span for sending alerts has passed
        if ($AlertFileTime)
            {$AlertTimeSpan = New-TimeSpan $AlertFileTime $(Get-Date -format g)
            $AlertTimeDifference = $AlertTimeSpan.TotalSeconds 
                if (!$AlertTimeDifference) { $SendEmail = $True }
                if ($AlertTimeDifference -ge $EmailAlertsLagTime) { $SendEmail = $True }
                else { $SendEmail = $False 
                " " | LogMe -display
                }
            }
        if (!$AlertFileTime) { $SendEmail = $True }

        # Checking Alert Log Contents from last run for comparison
        if (Test-Path $AlertsEmailed) { $AlertLogContents = gc $AlertsEmailed }
        else 
            {
            " " | LogMe -display 
            "Alerts Email Log does not exist" | LogMe -display
            }

        # Checking Current Errors and Warnings found this duration for comparison
        if (Test-Path $CurrentAlerts) { $CurrentAlertsContents = gc $CurrentAlerts }
        else 
            { 
            " " | LogMe -display 
            "Current Alerts Log does not exist" | LogMe -display 
            }

        # If the Alerts Email Log is empty but the Current Log is not, there are new alerts.
        If (!$AlertLogContents -and $CurrentAlertsContents) 
            {
            "Alert Log Contents is empty but Current Alerts Contents is not" | LogMe -display
            $NewAlerts = $True
            $SendEmail = $True 
            " " | LogMe -display
            "New Alerts Detected"  | LogMe -display
            } 
        # If the Alert Email Log and the Current Alert Log matches then there are most likely no new errors
        If ($AlertLogContents -and $CurrentAlertsContents) 
            {
            $AlertsDiff = compare-object $CurrentAlertsContents $AlertLogContents | Measure
            If ($AlertsDiff.count -ne 0) 
                    { $NewAlerts = $True 
                    " " | LogMe -display
                    "New Alerts Detected"  | LogMe -display
                    }
                else 
                    { $NewAlerts = $False 
                    " " | LogMe -display
                    "No New Alerts Detected"  | LogMe -display
                    } 
            }

    }
else {if (Test-Path $CurrentAlerts) {clear-content $CurrentAlerts}}

#=============================================================================================
#                                 Email Section
#=============================================================================================  
If ( ($NewAlerts -eq $True) -or ($SendEmail -eq $True) ) 
    { 
        if (Test-Path $AlertsEmailed) { clear-content $AlertsEmailed }
        #$CurrTime | Add-Content $AlertFile
        foreach ($line in $ErrorsandWarnings) { $Line | Add-Content $AlertsEmailed }

        # Setting MailFlag for the validation and error handling
        $MailFlag = $false 

        If(!$emailFrom) { $MailFlag = $True; Write-Warning "From Email is NULL" | LogMe -error }
        If(!$emailTo) { $MailFlag = $True; Write-Warning "To Email is NULL" | LogMe -error }
        If(!$smtpServer) { $MailFlag = $True; Write-Warning "SMTP Server is NULL" | LogMe -error }

        # $MailFlag = $True

        # Send email only if From, To and SMTP adress are not null
        if($MailFlag -match $True) { "Email could not send as the email parameters (FROM/TO/SMTP) failed"  | LogMe -error}
        
        # Send email only if there is either an Error or Warning Detected
        if($ErrorsDetected -match $True -or $WarningsDetected -match $True) 
            {
            $BODY = $WarningsHeader,$script:Warnings,$ErrorsHeader,$script:Errors,$MonitorURL
            $msg = new-object System.Net.Mail.MailMessage
            $msg.From=$emailFrom
            $msg.to.Add($emailTo)
            if($emailCC) { $msg.cc.add($emailCC) }
            $msg.Subject=$emailSubject
            $msg.IsBodyHtml=$true
            $msg.Body=$BODY
            $msg.Attachments.Add($logfile)
            $smtp = new-object System.Net.Mail.SmtpClient
            $smtp.host=$smtpServer
            Try { $smtp.Send($msg); "" | LogMe -display; "Email Sent" | LogMe -display }
            Catch { 
                    "" | LogMe -display
                    "Error Sending Email. See Error Messages Below:" | LogMe -error 
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    $ErrorMessage | LogMe -error
                    $FailedItem | LogMe -error
                  }
            Start-Sleep 2
            $msg.Dispose()
            if (Test-Path $AlertEmail) { clear-content $AlertEmail }
            $CurrTime | Add-Content $AlertEmail
            }
                else { "" | LogMe -display; "Not sending email since there were no Warnings or Errors detected" | LogMe -display }
            }


"" | LogMe -display
"Script Completed" | LogMe -display
"" | LogMe -display
"Script Ended at $(get-date)" | LogMe -display
$elapsed = GetElapsedTime $script:startTime
"Total Elapsed Script Time: $elapsed" | LogMe -display


#==============================================================================================
# END OF SCRIPT
#==============================================================================================

Start-Sleep -Seconds 30
