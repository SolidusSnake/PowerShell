Add-Type -AssemblyName "Microsoft.Office.Interop.Outlook" | Out-Null
$olFolders = "Microsoft.Office.Interop.Outlook.olDefaultFolders" -as [type]
$outlook = New-Object -ComObject Outlook.Application
$namespace = $outlook.GetNameSpace("MAPI")
$folder = $namespace.GetDefaultFolder($olFolders::olFolderInbox)
$reports = $folder.Folders.Item("TEMP")

#$reports.Items | Select-Object Subject, ReceivedTime | Sort-Object ReceivedTime -Descending

foreach ($item in ($reports.Items))
{
    $mail = $outlook.CreateItem(0)
    $subject = $item | Select-Object -ExpandProperty Subject
    $mail.To = "user@email.com"
    $mail.Subject = "$subject Rebooted"
    $mail.Body = "Rebooted"
    $mail.Save()
    
}
