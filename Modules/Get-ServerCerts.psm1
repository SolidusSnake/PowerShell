Function Get-ServerCerts
{

    [CmdletBinding(SupportsShouldProcess=$true)]
 
    Param
    (
    [Parameter(ValueFromPipeline=$true)]
    $ComputerName="localhost"
    )

    Begin
    {
        #$ErrorActionPreference = "SilentlyContinue"
        $table = New-Object System.Data.DataTable "Table"
        $col1 = New-Object System.Data.DataColumn "Subject",([string])
        $col2 = New-Object System.Data.DataColumn "Issuer",([string])
        $col3 = New-Object System.Data.DataColumn "Certificate Store",([string])
        $col4 = New-Object System.Data.DataColumn "Issued Date",([string])
        $col5 = New-Object System.Data.DataColumn "Expiration Date",([string])
        $col6 = New-Object System.Data.DataColumn "Expires In (Days)",([int])
        $col7 = New-Object System.Data.DataColumn "Server",([string])
        $table.Columns.Add($col1)
        $table.Columns.Add($col2)
        $table.Columns.Add($col3)
        $table.Columns.Add($col4)
        $table.Columns.Add($col5)
        $table.Columns.Add($col6)
        $table.Columns.Add($col7)
    }


    PROCESS
    {
        foreach ($Computer in $ComputerName)
        {
                $search = Invoke-Command -ComputerName $Computer -ScriptBlock { Get-ChildItem Cert:\LocalMachine\ -Recurse | where {$_.Subject -like "*power*" -or $_.FriendlyName -like "*power*"}}
            
                foreach ($cert in $search)
                {
                    $row = $table.NewRow()
                    $row.Server = [string]$cert.PSComputerName
                    $row.Subject = [string]$cert.Subject
                    $row.Issuer = [string]$cert.Issuer
                    $row."Certificate Store" = [string]($cert.PSParentPath).split(":")[2]
                    $row."Issued Date" = [string]$cert.NotBefore
                    $row."Expiration Date" = [string]$cert.NotAfter
                    $row."Expires In (Days)" = ($cert.NotAfter - (Get-Date)).Days
                    $table.rows.Add($row)
                }

                $table
        }
    }
}