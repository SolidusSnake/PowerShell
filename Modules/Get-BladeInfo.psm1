Function Get-BladeInfo
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
        $col1 = New-Object System.Data.DataColumn "Server",([string])
        $col2 = New-Object System.Data.DataColumn "Model",([string])
        $col3 = New-Object System.Data.DataColumn "Serial",([string])
        $col4 = New-Object System.Data.DataColumn "Rack",([string])
        $col5 = New-Object System.Data.DataColumn "Enclosure",([string])
        $col6 = New-Object System.Data.DataColumn "Blade",([string])
        $table.Columns.Add($col1)
        $table.Columns.Add($col2)
        $table.Columns.Add($col3)
        $table.Columns.Add($col4)
        $table.Columns.Add($col5)
        $table.Columns.Add($col6)
    }

    PROCESS
    {
        foreach ($Computer in $ComputerName)
        {
            $server = New-Object System.Xml.XmlDocument
            $enclosure = New-Object System.Xml.XmlDocument

            $server.Load("http://$Computer/xmldata?item=All")
            $enclosureIP = $server.RIMP.BLADESYSTEM.MANAGER.MGMTIPADDR
            $enclosure.Load("http://$enclosureIP/xmldata?item=All")

            $dns = $enclosure.RIMP.INFRA2.BLADES.BLADE | Where-Object {$_.BSN -like $server.RIMP.HSI.SBSN} | Select-Object -ExpandProperty MGMTDNSNAME

            $row = $table.NewRow()
            $row.Server = [string]$dns
            $row.Model = [string]$server.RIMP.HSI.SPN
            $row.Serial = [string]$server.RIMP.HSI.SBSN
            $row.Rack = [string]$server.RIMP.BLADESYSTEM.MANAGER.RACK
            $row.Enclosure = [string]$server.RIMP.BLADESYSTEM.MANAGER.ENCL
            $row.Blade = [string]$server.RIMP.BLADESYSTEM.BAY
            $table.rows.Add($row)
        }

        $table
    }
}
