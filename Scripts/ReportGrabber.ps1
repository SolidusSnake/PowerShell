
Add-type -assembly "Microsoft.Office.Interop.Outlook" | out-null
$olFolders = "Microsoft.Office.Interop.Outlook.olDefaultFolders" -as [type]
$outlook = new-object -comobject outlook.application
$namespace = $outlook.GetNameSpace("MAPI")

## To get the folder paths, run: $namespace.folders | select folderpath

$folder = $namespace.getDefaultFolder($olFolders::olFolderInBox)
$junk = $folder.Folders.Item("Folder Name")
#$folder = $namespace.Folders.Item("Tech Lead Email")
#$junk.items | Select-Object -Property Subject, ReceivedTime, Importance, SenderName | sort ReceivedTime -descending


$date = Get-date
$filepath = "$env:userprofile\desktop\"
$junk.items | foreach {
	IF ($_.ReceivedTime -gt (Get-Date).AddDays(-1)) {
	$_.attachments | foreach {
		#Write-Host $_.filename
		$file = $_.filename
		If ($file.Contains("PART OF FILE NAME")) {
			$_.saveasfile((Join-Path $filepath $_.filename))
		}
	}
}
}

function ConvertFrom-Xlx
{
	param
	(
		[parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[string]$path,
		[switch]$PassThru
	)
	
	begin
	{
		$objExcel = New-Object -ComObject Excel.Application
	}
	
	process
	{
		if ((Test-Path $path) -and ($path -match ".xl\w*$"))
		{
			$path = (Resolve-Path -Path $path).path
			$savePath = $path -replace ".xl\w*$",".csv"
			$objworkbook = $objExcel.Workbooks.Open($path)
			$objworkbook.SaveAs($savePath,6) ## 6 is the code for .CSV
			$objworkbook.Close($false)
			
			if ($PassThru)
			{
				Import-Csv -Path $savePath
			}
		}
		else
		{
			Write-Host "$path : not found"
		}
	}
	
	end
	{
		$objExcel.Quit()
	}
}

$file = "$env:userprofile\desktop\Report001.xlsx"

$excel = New-Object -ComObject Excel.Application
$excel.visible = $False
$workbook = $excel.Workbooks.Open($file) ## Open the file
$i=0;$workbook.Worksheets | %{$i++;@{$_.name=$i}} ## List worksheet values
$excel.DisplayAlerts = $False
$workbook.Worksheets.Item(6..15).Delete() ## Delete tabs 6 through 15
$workbook.Worksheets.Item(1..4).Delete() ## Delete tabs 1 through 4
$sheet = $workbook.Sheets.Item("TabName") ## Activate the first worksheet
[void]$sheet.Cells.Item(1, 1).EntireRow.Delete() ## Delete the first row
[void]$sheet.Cells.Item(1, 1).EntireRow.Delete() ## Delete the first row
[void]$sheet.Cells.Item(1, 1).EntireRow.Delete() ## Delete the first row
$workbook.Close($true) ## Close workbook and save changes
$excel.quit() ## Quit Excel
[Runtime.Interopservices.Marshal]::ReleaseComObject($excel) ## Release COM

ConvertFrom-Xlx -path "$env:userprofile\desktop\Report001.xlsx" ## Convert the document to CSV

$csv = Get-Content "$env:userprofile\desktop\Report001.csv"
$csv | Foreach-Object {$_ -replace "Notes,","Notes"} | Set-Content "$env:userprofile\desktop\Report002.csv" ## Replace the last header to remove the ','

## Match only servers specified
$final = Import-Csv "$env:userprofile\desktop\Report002.csv"
$final | where {$_."Host Name" -match "server01|server02|server03|server04"} | Select "Workload","Host Name","_V     ERRORED","_VM ERRORED","BPBKAR Last FULL","BPBKAR Last FULL Status","BPBKAR Last INCR","BPBKAR Last INCR Status","BPBKAR ERRORED","BLA Version","BL Description","Netbackup Version" | Export-CSV "$env:userprofile\desktop\Final Report.csv" -NoTypeInformation

## Remove previous copies 
Remove-Item "$env:userprofile\desktop\Report001.csv"
Remove-Item "$env:userprofile\desktop\Report002.csv"
Remove-Item "$env:userprofile\desktop\Report001.xlsx"


## Prepare report to be sent out
$report = "$env:userprofile\desktop\Final Report.csv"
$Outlook = New-Object -comObject Outlook.Application
$body = "NetBackup Reports" 
$mail = $Outlook.CreateItem(0)
$mail.To = "email.one@mail.com"
$mail.CC = "email.two@mail.com"
$mail.Subject = "NetBackup Reports"
$mail.Attachments.Add($report)
$mail.Body = $Body
$mail.save()
$mail.GetInspector.Display()

Write-Host "Press any key to continue ..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
