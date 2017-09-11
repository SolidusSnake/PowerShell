Add-Type -assembly "Microsoft.Office.Interop.Outlook"
$Outlook = New-Object -comobject Outlook.Application
$namespace = $Outlook.GetNameSpace("MAPI")
$folder = $namespace.Folders.Item(4).Folders.Item(2).Folders.Item('ACAS')

$date = Get-Date
$filePath = "C:\DATA\ACAS"
$folder.Items | foreach {
    #if ($_.ReceivedTime -gt (Get-Date).AddDays(-1)) {
    $_.attachments | foreach {
        $file = $_.filename 
        if ($file.Contains(".csv") -and (($file.Contains("filename1"))) -or ($file.Contains("filename2"))) {
            $_.saveasfile((Join-Path $filepath $_.filename))
        }
    }
}
#}

$date1 = Get-Date -Format "MM-dd-yyyy"
$output = "C:\DATA\ACAS\SCANS_$date1.xlsx"
$csv = Get-ChildItem -Path C:\DATA\ACAS\*.csv | Select-Object -ExpandProperty FullName

foreach ($file in $csv)
{
    Import-Csv -Path $file | Export-Csv -NoTypeInformation "C:\DATA\ACAS\SCANS_$date1.csv" -Append -Force
}

$excelParams = @{AutoSize = $true; AutoFilter = $true; FreezeTopRow = $true}
Import-Csv "C:\DATA\ACAS\SCANS_$date1.csv" | Select-Object @{l='HOST';e={$_."DNS Name"}},Plugin,Severity,"Plugin Name","Plugin Text","First Discovered","Last Observed" | Export-Excel $output @excelParams

Get-ChildItem -Path "C:\DATA\ACAS" | where {$_.Extension -like "*.csv*"} | Remove-Item

$wshshell = New-Object -ComObject WScript.Shell
$desktop = [System.Environment]::GetFolderPath('Desktop')
$lnk = $wshshell.CreateShortcut($desktop+"\ACAS Scans.lnk")
$lnk.TargetPath = "c:\DATA\ACAS\SCANS_$date1.xlsx"
$lnk.Save() 
