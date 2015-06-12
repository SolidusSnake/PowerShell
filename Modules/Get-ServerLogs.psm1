Function Get-ServerLogs
{

    [CmdletBinding(SupportsShouldProcess=$true)]
 
    Param
    (
    [Parameter(ValueFromPipeline=$true)]
    $ComputerName="localhost",
    [Parameter(Mandatory=$true)]
    $Logname
    )

    Begin
    {
        #$ErrorActionPreference = "SilentlyContinue"
        $table = New-Object System.Data.DataTable "Table"
        $col1 = New-Object System.Data.DataColumn "Server",([string])
        $col2 = New-Object System.Data.DataColumn "Log Name",([string])
        $col3 = New-Object System.Data.DataColumn "Event ID",([string])
        $col4 = New-Object System.Data.DataColumn "Entry Type",([string])
        $col5 = New-Object System.Data.DataColumn "Message",([string])
        $col6 = New-Object System.Data.DataColumn "Time Generated",([string])
        $col7 = New-Object System.Data.DataColumn "UserName",([string])
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
                $search = Get-EventLog -ComputerName $computer -LogName $Logname -After (Get-Date).AddDays(-1) -EntryType Error,Warning
            
                foreach ($log in $search)
                {
                    $row = $table.NewRow()
                    $row.Server = [string]$log.MachineName
                    $row."Log Name" = [string]$Logname
                    $row."Event ID" = [string]$log.EventID
                    $row."Entry Type" = [string]$log.EntryType
                    $row.Message = [string]$log.Message
                    $row."Time Generated" = [string]$log.TimeGenerated
                    $row.UserName = [string]$log.UserName
                    $table.rows.Add($row)
                }

                $table
        }
    }
}