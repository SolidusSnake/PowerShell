Clear
# Continue even if there are errors
$ErrorActionPreference = "Continue";

# Set your warning and critical thresholds
$percentWarning = 15;
$percentCritcal = 10;

# REPORT PROPERTIES
	# Path to the report
		$reportPath = "X:\Disk-Reports\";

	# Report name
		$reportName = "DiskSpaceRpt_Servers_$(get-date -format yyyyMMdd).html";


#Set colors for table cell backgrounds
$redColor = "#FF0000"
$orangeColor = "#FBB917"
$whiteColor = "#FFFFFF"

# Count if any computers have low disk space.  Do not send report if less than 1.
$i = 0;

# Get computer list to check disk space
$list = Get-Content X:\servers.txt

$diskReport = $reportPath + $reportName

# Remove the report if it has already been run today so it does not append to the existing report
If (Test-Path $diskReport)
    {
        Remove-Item $diskReport
    }

$computers = $list | where {$_ -notlike $null } | foreach { $_.trim() }

# Create and write HTML Header of report
$titleDate = get-date -uformat "%m-%d-%Y - %A"
$header = "
		<html>
		<head>
		<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>
		<title>DiskSpace Report</title>
		<STYLE TYPE='text/css'>
		<!--
		td {
			font-family: Tahoma;
			font-size: 12px;
			border-top: 1px solid #999999;
			border-right: 1px solid #999999;
			border-bottom: 1px solid #999999;
			border-left: 1px solid #999999;
			padding-top: 0px;
			padding-right: 0px;
			padding-bottom: 0px;
			padding-left: 0px;
		}
		body {
			margin-left: 5px;
			margin-top: 5px;
			margin-right: 0px;
			margin-bottom: 10px;
			table {
			border: thin solid #000000;
		}
		-->
		</style>
		</head>
		<body>
		<table width='1000'>
		<tr bgcolor='#CCCCCC'>
		<td colspan='7' height='25' align='center'>
		<font face='tahoma' color='#003399' size='4'><strong>Environment Disk Space Report for $titledate</strong></font>
		</td>
		</tr>
		</table>
"
Add-Content $diskReport $header

# Create and write Table header for report
 $tableHeader = "
 <table width='1000'><tbody>
	<tr bgcolor=#CCCCCC>
    <td width='150' align='center'>Server</td>
	<td width='150' align='center'>IP</td>
	<td width='85' align='center'>VM/Physical</td>
	<td width='50' align='center'>Drive</td>
	<td width='85' align='center'>Drive Label</td>
	<td width='105' align='center'>Total Capacity(GB)</td>
	<td width='105' align='center'>Used Capacity(GB)</td>
	<td width='105' align='center'>Free Space(GB)</td>
	<td width='85' align='center'>Freespace %</td>
	</tr>
"
Add-Content $diskReport $tableHeader
 
# Start processing disk space reports against a list of servers
  foreach($computer in $computers)
	{	
		If (Test-Connection -count 1 -computer $computer -quiet) {
			$disks = Get-WmiObject -ComputerName $computer -Class Win32_LogicalDisk -Filter "DriveType = 3"
			#$IP = Get-WmiObject -query "SELECT IPAddress FROM win32_NetworkAdapterConfiguration where IPEnabled='True'" -computer $computer
			#$IP = Get-WmiObject win32_NetworkAdapterConfiguration -computer $computer | where {$_.IPEnabled -eq "True" -and $_.IPAddress -like "*1.2.*" -or $_.IPAddress -like "*1.3.*" -or $_.IPAddress -like "*1.4.*"}
			$IP = Get-WmiObject win32_NetworkAdapterConfiguration -computer $computer | where {$_.IPEnabled -eq "True" -and $_.IPAddress -match "1.2.|1.3.|1.4."}

			$VMPhy = Get-WmiObject -class "Win32_ComputerSystem" -namespace "root\CIMV2" -computername $computer
			$computer = $computer.toupper()
				foreach($disk in $disks)
					{        
						$deviceID = $disk.DeviceID;
						$volName = $disk.VolumeName;
						[float]$size = $disk.Size;
						[float]$freespace = $disk.FreeSpace; 
						$percentFree = [Math]::Round(($freespace / $size) * 100, 2);
						$sizeGB = [Math]::Round($size / 1GB, 2);
						$freeSpaceGB = [Math]::Round($freespace / 1GB, 2);
						$usedSpaceGB = [Math]::Round($sizeGB - $freeSpaceGB, 2);
						$color = $whiteColor;
						$IPAdd = [string]$IP.IPAddress[0] 
							If ($VMPhy.Manufacturer -eq "VMware, Inc." -or $VMPhy.Manufacturer -eq "Microsoft Corporation") {
								$Type = "Virtual"}
							Else {
								$Type = "Physical"}

# Set background color to Orange if just a warning
    if($percentFree -lt $percentWarning)      
	{
	$color = $orangeColor	
	}
# Set background color to Red if space is Critical
    if($percentFree -lt $percentCritcal)
        {
        $color = $redColor
        }
		
# Leave background color White if free space is >15%	
    if($percentFree -gt $percentWarning)
        {
        $color = $whiteColor
        }	  	
 
 # Create table data rows 
    $dataRow = "
		<tr>
        <td width='150'>$computer</td>
		<td width='150'>$IPAdd</td>
		<td width='85'>$Type</td>
		<td width='50' align='center'>$deviceID</td>
		<td width='85' >$volName</td>
		<td width='105' align='center'>$sizeGB</td>
		<td width='105' align='center'>$usedSpaceGB</td>
		<td width='105' align='center'>$freeSpaceGB</td>
		<td width='85' bgcolor=`'$color`' align='center'>$percentFree</td>
		</tr>
"
Add-Content $diskReport $dataRow;
Write-Host "$computer $deviceID percentage free space = $percentFree"
		
	}
	$i++	
	Write-Progress -Activity "Gathering data" -status "Processed computer $i of $($computers.length)" -percentComplete ($i / $computers.length*100)
	}
	Else { 
				Write-Host "Unable to connect to $computer" -back Black -fore Yellow
				$i++
		}#endelse
}

# Create table at end of report showing legend of colors for the critical and warning
 $tableDescription = "
 </table><br><table width='600'>
	<tr bgcolor='White'>
	<td width='200' align='center' bgcolor='#FFFFFF'>Normal gtr than 15% free space</td>
    <td width='200' align='center' bgcolor='#FBB917'>Warning less than 15% free space</td>
	<td width='200' align='center' bgcolor='#FF0000'>Critical less than 10% free space</td>
	</tr>
"
 	Add-Content $diskReport $tableDescription
	Add-Content $diskReport "</body></html>"
