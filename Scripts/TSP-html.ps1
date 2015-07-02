function ConvertTo-EnhancedHTML {

    [CmdletBinding()]
    param(
        [string]$jQueryURI = 'http://ajax.aspnetcdn.com/ajax/jQuery/jquery-1.8.2.min.js',
        [string]$jQueryDataTableURI = 'http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.3/jquery.dataTables.min.js',
        [Parameter(ParameterSetName='CSSContent')][string[]]$CssStyleSheet,
        [Parameter(ParameterSetName='CSSURI')][string[]]$CssUri,
        [string]$Title = 'Report',
        [string]$PreContent,
        [string]$PostContent,
        [Parameter(Mandatory=$True)][string[]]$HTMLFragments
    )

    <#
        Add CSS style sheet. If provided in -CssUri, add a <link> element.
        If provided in -CssStyleSheet, embed in the <head> section.
        Note that BOTH may be supplied - this is legitimate in HTML.
    #>
    Write-Verbose "Making CSS style sheet"
    $stylesheet = ""
    if ($PSBoundParameters.ContainsKey('CssUri')) {
        $stylesheet = "<link rel=`"stylesheet`" href=`"$CssUri`" type=`"text/css`" />"
    }
    if ($PSBoundParameters.ContainsKey('CssStyleSheet')) {
        $stylesheet = $CssStyleSheet | Out-String
    }

    <#
        Create the HTML tags for the page title, and for
        our main javascripts.
    #>
    Write-Verbose "Creating <TITLE> and <SCRIPT> tags"
    $titletag = ""
    if ($PSBoundParameters.ContainsKey('title')) {
        $titletag = "<title>$title</title>"
    }
    $script += "<script type=`"text/javascript`" src=`"$jQueryURI`"></script>`n<script type=`"text/javascript`" src=`"$jQueryDataTableURI`"></script>"

    <#
        Render supplied HTML fragments as one giant string
    #>
    Write-Verbose "Combining HTML fragments"
    $body = $HTMLFragments | Out-String

    <#
        If supplied, add pre- and post-content strings
    #>
    Write-Verbose "Adding Pre and Post content"
    if ($PSBoundParameters.ContainsKey('precontent')) {
        $body = "$PreContent`n$body"
    }
    if ($PSBoundParameters.ContainsKey('postcontent')) {
        $body = "$PostContent`n$body"
    }

    <#
        Add a final script that calls the datatable code
        We dynamic-ize all tables with the .enhancedhtml-dynamic-table
        class, which is added by ConvertTo-EnhancedHTMLFragment.
    #>
    Write-Verbose "Adding interactivity calls"
    $datatable = ""
    $datatable = "<script type=`"text/javascript`">"
    $datatable += '$(document).ready(function () {'
    $datatable += "`$('.enhancedhtml-dynamic-table').dataTable();"
    $datatable += '} );'
    $datatable += "</script>"

    <#
        Datatables expect a <thead> section containing the
        table header row; ConvertTo-HTML doesn't produce that
        so we have to fix it.
    #>
    Write-Verbose "Fixing table HTML"
    $body = $body -replace '<tr><th>','<thead><tr><th>'
    $body = $body -replace '</th></tr>','</th></tr></thead>'

    <#
        Produce the final HTML. We've more or less hand-made
        the <head> amd <body> sections, but we let ConvertTo-HTML
        produce the other bits of the page.
    #>
    Write-Verbose "Producing final HTML"
    ConvertTo-HTML -Head "$stylesheet`n$titletag`n$script`n$datatable" -Body $body  
    Write-Debug "Finished producing final HTML"

}

function ConvertTo-EnhancedHTMLFragment {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [object[]]$InputObject,

        [string]$EvenRowCssClass,
        [string]$OddRowCssClass,
        [string]$TableCssID,
        [string]$DivCssID,
        [string]$DivCssClass,
        [string]$TableCssClass,

        [ValidateSet('List','Table')]
        [string]$As = 'Table',

        [object[]]$Properties = '*',

        [string]$PreContent,

        [switch]$MakeHiddenSection,

        [switch]$MakeTableDynamic,

        [string]$PostContent
    )
    BEGIN {
        <#
            Accumulate output in a variable so that we don't
            produce an array of strings to the pipeline, but
            instead produce a single string.
        #>
        $out = ''

        <#
            Add the section header (pre-content). If asked to
            make this section of the report hidden, set the
            appropriate code on the section header to toggle
            the underlying table. Note that we generate a GUID
            to use as an additional ID on the <div>, so that
            we can uniquely refer to it without relying on the
            user supplying us with a unique ID.
        #>
        Write-Verbose "Precontent"
        if ($PSBoundParameters.ContainsKey('PreContent')) {
            if ($PSBoundParameters.ContainsKey('MakeHiddenSection')) {
               [string]$tempid = [System.Guid]::NewGuid()
               $out += "<span class=`"sectionheader`" onclick=`"`$('#$tempid').toggle(500);`">$PreContent</span>`n"
            } else {
                $out += $PreContent
                $tempid = ''
            }
        }

        <#
            The table will be wrapped in a <div> tag for styling
            purposes. Note that THIS, not the table per se, is what
            we hide for -MakeHiddenSection. So we will hide the section
            if asked to do so.
        #>
        Write-Verbose "DIV"
        if ($PSBoundParameters.ContainsKey('DivCSSClass')) {
            $temp = " class=`"$DivCSSClass`""
        } else {
            $temp = ""
        }
        if ($PSBoundParameters.ContainsKey('MakeHiddenSection')) {
            $temp += "id=`"$tempid`" style=`"display:none;`""
        } else {
            $tempid = ''
        }
        if ($PSBoundParameters.ContainsKey('DivCSSID')) {
            $temp += " id=`"$DivCSSID`""
        }
        $out += "<div $temp>"

        <#
            Create the table header. If asked to make the table dynamic,
            we add the CSS style that ConvertTo-EnhancedHTML will look for
            to dynamic-ize tables.
        #>
        Write-Verbose "TABLE"
        $_TableCssClass = ''
        if ($PSBoundParameters.ContainsKey('MakeTableDynamic') -and $As -eq 'Table') {
            $_TableCssClass += 'enhancedhtml-dynamic-table '
        }
        if ($PSBoundParameters.ContainsKey('TableCssClass')) {
            $_TableCssClass += $TableCssClass
        }
        if ($_TableCssClass -ne '') {
            $css = "class=`"$_TableCSSClass`""
        } else {
            $css = ""
        }
        if ($PSBoundParameters.ContainsKey('TableCSSID')) {
            $css += "id=`"$TableCSSID`""
        } else {
            if ($tempid -ne '') {
                $css += "id=`"$tempid`""
            }
        }
        $out += "<table $css>"

        <#
            We're now setting up to run through our input objects
            and create the table rows
        #>
        $fragment = ''
        $wrote_first_line = $false
        $even_row = $false

        if ($properties -eq '*') {
            $all_properties = $true
        } else {
            $all_properties = $false
        }

    }
    PROCESS {

        foreach ($object in $inputobject) {
            Write-Verbose "Processing object"
            $datarow = ''
            $headerrow = ''

            <#
                Apply even/odd row class. Note that this will mess up the output
                if the table is made dynamic. That's noted in the help.
            #>
            if ($PSBoundParameters.ContainsKey('EvenRowCSSClass') -and $PSBoundParameters.ContainsKey('OddRowCssClass')) {
                if ($even_row) {
                    $row_css = $OddRowCSSClass
                    $even_row = $false
                    Write-Verbose "Even row"
                } else {
                    $row_css = $EvenRowCSSClass
                    $even_row = $true
                    Write-Verbose "Odd row"
                }
            } else {
                $row_css = ''
                Write-Verbose "No row CSS class"
            }

            <#
                If asked to include all object properties, get them.
            #>
            if ($all_properties) {
                $properties = $object | Get-Member -MemberType Properties | Select -ExpandProperty Name
            }

            <#
                We either have a list of all properties, or a hashtable of
                properties to play with. Process the list.
            #>
            foreach ($prop in $properties) {
                Write-Verbose "Processing property"
                $name = $null
                $value = $null
                $cell_css = ''

                <#
                    $prop is a simple string if we are doing "all properties,"
                    otherwise it is a hashtable. If it's a string, then we
                    can easily get the name (it's the string) and the value.
                #>
                if ($prop -is [string]) {
                    Write-Verbose "Property $prop"
                    $name = $Prop
                    $value = $object.($prop)
                } elseif ($prop -is [hashtable]) {
                    Write-Verbose "Property hashtable"
                    <#
                        For key "css" or "cssclass," execute the supplied script block.
                        It's expected to output a class name; we embed that in the "class"
                        attribute later.
                    #>
                    if ($prop.ContainsKey('cssclass')) { $cell_css = $Object | ForEach $prop['cssclass'] }
                    if ($prop.ContainsKey('css')) { $cell_css = $Object | ForEach $prop['css'] }

                    <#
                        Get the current property name.
                    #>
                    if ($prop.ContainsKey('n')) { $name = $prop['n'] }
                    if ($prop.ContainsKey('name')) { $name = $prop['name'] }
                    if ($prop.ContainsKey('label')) { $name = $prop['label'] }
                    if ($prop.ContainsKey('l')) { $name = $prop['l'] }

                    <#
                        Execute the "expression" or "e" key to get the value of the property.
                    #>
                    if ($prop.ContainsKey('e')) { $value = $Object | ForEach $prop['e'] }
                    if ($prop.ContainsKey('expression')) { $value = $tObject | ForEach $prop['expression'] }

                    <#
                        Make sure we have a name and a value at this point.
                    #>
                    if ($name -eq $null -or $value -eq $null) {
                        Write-Error "Hashtable missing Name and/or Expression key"
                    }
                } else {
                    <#
                        We got a property list that wasn't strings and
                        wasn't hashtables. Bad input.
                    #>
                    Write-Warning "Unhandled property $prop"
                }

                <#
                    When constructing a table, we have to remember the
                    property names so that we can build the table header.
                    In a list, it's easier - we output the property name
                    and the value at the same time, since they both live
                    on the same row of the output.
                #>
                if ($As -eq 'table') {
                    Write-Verbose "Adding $name to header and $value to row"
                    $headerrow += "<th>$name</th>"
                    $datarow += "<td$(if ($cell_css -ne '') { ' class="'+$cell_css+'"' })>$value</td>"
                } else {
                    $wrote_first_line = $true
                    $headerrow = ""
                    $datarow = "<td$(if ($cell_css -ne '') { ' class="'+$cell_css+'"' })>$name :</td><td$(if ($css -ne '') { ' class="'+$css+'"' })>$value</td>"
                    $out += "<tr$(if ($row_css -ne '') { ' class="'+$row_css+'"' })>$datarow</tr>"
                }
            }

            <#
                Write the table header, if we're doing a table.
            #>
            if (-not $wrote_first_line -and $as -eq 'Table') {
                Write-Verbose "Writing header row"
                $out += "<tr>$headerrow</tr><tbody>"
                $wrote_first_line = $true
            }

            <#
                In table mode, write the data row.
            #>
            if ($as -eq 'table') {
                Write-Verbose "Writing data row"
                $out += "<tr$(if ($row_css -ne '') { ' class="'+$row_css+'"' })>$datarow</tr>"
            }
        }
    }
    END {
        <#
            Finally, post-content code, the end of the table,
            the end of the <div>, and write the final string.
        #>
        Write-Verbose "PostContent"
        if ($PSBoundParameters.ContainsKey('PostContent')) {
            $fragment = "$PostContent`n$fragment"
        }
        Write-Verbose "Done"
        $out += "</tbody></table></div>"
        Write-Output $out
    }
}

function Get-Report{
[CmdletBinding()]
param(
<#

#>
)
BEGIN {
    #$ComputerName = Read-Host "Enter server name"
    $ComputerName = $env:COMPUTERNAME
    $Path = Read-Host "Enter output directory"
}
PROCESS {

$style = @"
<style>
body {
    color:#333333;
    font-family:Calibri,Tahoma;
    font-size: 10pt;
}
h1 {
    text-align:center;
}
h2 {
    border-top:1px solid #666666;
}

th {
    font-weight:bold;
    color:#eeeeee;
    background-color:#333333;
    cursor:pointer;
}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
.paginate_enabled_next, .paginate_enabled_previous {
    cursor:pointer; 
    border:1px solid #222222; 
    background-color:#dddddd; 
    padding:2px; 
    margin:4px;
    border-radius:2px;
}
.paginate_disabled_previous, .paginate_disabled_next {
    color:#666666; 
    cursor:pointer;
    background-color:#dddddd; 
    padding:2px; 
    margin:4px;
    border-radius:2px;
}
.dataTables_info { margin-bottom:4px; }
.sectionheader { cursor:pointer; }
.sectionheader:hover { color:red; }
.grid { width:100% }
.red {
    color:red;
    font-weight:bold;
} 
</style>
"@


function Get-InfoOS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$ComputerName
    )
	Write-Host "Getting operating system information..." -background Black -foreground Yellow
    $os = Get-WmiObject -class Win32_OperatingSystem -ComputerName $ComputerName
    $props = @{'Product'=$os.caption;
               'OS Version'=$os.version;
               'Service Pack Version'=$os.servicepackmajorversion}
    New-Object -TypeName PSObject -Property $props
}

function Get-Events {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$ComputerName
    )
    $logcheck = Read-Host "Do you want to check event logs?
[Y]es or [N]o"

If ($logcheck -eq "Y")
{
	Write-Host "This will search for 'Error' and 'Warning' entries in SYSTEM and APPLICATION logs." -background Black -foreground Yellow
	Write-Host "This will search for 'FailureAudit' and 'SuccessAudit' in SECURITY logs." -background Black -foreground Yellow 
	Sleep -Seconds 3
    $Log = Read-Host "What Log do you want information from? (System, Application, or Security)"
    $EvtStart = Read-Host "Start Time Requested (MM/DD/YYYY HH:MM AM/PM)"
    $EvtEnd = Read-Host "End Time Reqested (MM/DD/YYYY HH:MM AM/PM)"

	If ($Log -match "System|Application")
	{
	Write-Host "Checking event logs..." -background Black -foreground Yellow
    $evtlog = Get-EventLog $log -ComputerName $Computer -after "$EvtStart" -Before "$EvtEnd" -EntryType Error,Warning 
	}
	
	Else
	{
	Write-Host "Checking event logs..." -background Black -foreground Yellow
	$evtlog = Get-EventLog $log -ComputerName $Computer -after "$EvtStart" -Before "$EvtEnd" -EntryType FailureAudit,SuccessAudit
	}
}

Else
{
    Write-Host "Skipping event logs" -background Black -foreground Yellow
}

foreach ($evtl in $evtlog){
   $props = @{'Computer Name'=$evtl.MachineName;
              'Message'= $evtl.Message;
              'Event ID'= $evtl.EventID;
			  'Entry Type'=$evtl.EntryType;
              'Time Written'=$evtl.TimeWritten;}
              
    New-Object -TypeName PSObject -Property $props
}
}

function Get-InfoCompSystem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$ComputerName
    )
	Write-Host "Getting system information..." -background Black -foreground Yellow
    $cs = Get-WmiObject -class Win32_ComputerSystem -ComputerName $ComputerName
	$cp = Get-WmiObject -class Win32_Processor -ComputerName $ComputerName
    $props = @{'Model'=$cs.model;
               'Manufacturer'=$cs.manufacturer;
               'RAM (GB)'="{0:N2}" -f ($cs.totalphysicalmemory / 1GB);
			   'Processor'=$cp.name;
               'Sockets'=$cs.numberofprocessors;
               'Cores'=$cs.numberoflogicalprocessors;
               'Part of domain'=$cs.partofdomain;
               'Domain name'=$cs.domain}
    New-Object -TypeName PSObject -Property $props
}

function Get-InfoBadService {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$ComputerName
    )
	Write-Host "Checking services..." -background Black -foreground Yellow
    $svcs = Get-WmiObject -class Win32_Service -ComputerName $ComputerName -Filter "StartMode='Auto' AND State<>'Running'"
    foreach ($svc in $svcs) {
        $props = @{'Service Name'=$svc.name;
                   'Display Name'=$svc.displayname}
        New-Object -TypeName PSObject -Property $props
        }
  }

function Get-InstalledPatches {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$ComputerName
    )
	Write-Host "Getting installed patches..." -background Black -foreground Yellow
    $ptchs = Get-HotFix -ComputerName $Computer | sort -descending installedon | Select-Object PSComputerName, HotFixID, InstalledOn, InstalledBy -first 15 
    foreach ($ptch in $ptchs){
    $props = @{'Computer Name'=$ptch.PSComputername;
               'HotFix ID'=$ptch.HotFixID;
               'Installed On'=$ptch.InstalledOn;
               'Installed By'=$ptch.InstalledBy;}
               
    New-Object -TypeName PSObject -Property $props
}
}

function Get-PerRoutes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$ComputerName
    )
	Write-Host "Getting persistent routes..." -background Black -foreground Yellow
    $proutes = Get-WmiObject -class win32_ip4persistedroutetable -ComputerName $Computer | Select-Object PScomputerName, Name, Mask, NextHop, Metric1
    foreach ($proute in $proutes){
    $props = @{'Computer Name'=$proute.PSComputername;
               'Network Address'=$proute.Name;
               'Subnet Mask'=$proute.Mask;
               'Gateway Address'=$proute.NextHop;
               'Metric'=$proute.Metric1;}
               
    New-Object -TypeName PSObject -Property $props
}
}

function Get-InfoProc {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$ComputerName
    )
	Write-Host "Getting processes..." -background Black -foreground Yellow
    $procs = Get-WmiObject -class Win32_Process -ComputerName $ComputerName | sort -Descending WS  |  select -First 15 
    foreach ($proc in $procs) { 
        $props = @{'Name'=$proc.name;
                   'Memory Being Used (MB)'=$proc.WorkingSetSize / 1MB -as [int]}
        New-Object -TypeName PSObject -Property $props
    }
    }

function Get-InfoNIC {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$ComputerName
    )
	Write-Host "Getting NIC properties..." -background Black -foreground Yellow
    #$nics = Get-WmiObject -class Win32_NetworkAdapter -ComputerName $ComputerName -Filter "PhysicalAdapter=True"
    $na = Get-WmiObject -Class Win32_NetworkAdapter -ComputerName $ComputerName | Where {$_.PhysicalAdapter -eq "True" -and $_.speed -notlike "$null"}
    $nac = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $ComputerName | Where {$_.IPAddress -notlike "$null"}
    #$nics = Get-WmiObject -Class Win32_NetworkAdapter -ComputerName $ComputerName | Where {$_.PhysicalAdapter -eq "True" -and $_.speed -notlike "$null"}
    forEach($Index in ($NA | Select -Expand Index))
{
    $props = @{
        'Adapter Label'=[String]($na | where {$_.Index -eq $Index}).netconnectionid
        'Link Speed (Gbps)'=($na | where {$_.Index -eq $Index}).speed / 1GB -as [int];
        'MAC Address'=[String]($na | where {$_.Index -eq $Index}).MACAddress
        'IP Address'=[String]($nac | where {$_.Index -eq $Index}).IPAddress
        'Subnet Mask'=[String]($nac | where {$_.Index -eq $Index}).IPSubnet
        'Default Gateway'=[String]($nac | where {$_.Index -eq $Index}).DefaultIPGateway}
        New-Object -TypeName PSObject -Property $props
    }
    }
function Get-InfoDisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$ComputerName
    )
	Write-Host "Getting drive information..." -background Black -foreground Yellow
    $drives = Get-WmiObject -class Win32_LogicalDisk -ComputerName $ComputerName `
           -Filter "DriveType=3"
    foreach ($drive in $drives) {      
        $props = @{'Drive'=$drive.DeviceID;
                   'Total Size (GB)'=$drive.size / 1GB -as [int];
                   'Free Space (GB)'="{0:N2}" -f ($drive.freespace / 1GB);
                   'Free Space (%)'=$drive.freespace / $drive.size * 100 -as [int]}
        New-Object -TypeName PSObject -Property $props  
    }
    }
function Get-Connections {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$ComputerName
    )
    IF ($Computer -like "*site01*")
{
    Write-Host "Testing Site01 DNS connection..."
   $connections = Invoke-Command -ComputerName $Computer -ScriptBlock {Test-Connection 1.1.1.1 -Count 2} | Select-Object PSComputerName,IPV4Address,ResponseTime 
   $connections = Invoke-Command -ComputerName $Computer -ScriptBlock {Test-Connection 1.1.1.2 -Count 2} | Select-Object PSComputerName,IPV4Address,ResponseTime 
}

# Site02
Elseif ($Computer -like "*site02*")
{
    Write-Host "Testing Site02 DNS connection..."
    $connections =Invoke-Command -ComputerName $Computer -ScriptBlock {Test-Connection 1.1.2.1 -Count 2} | Select-Object PSComputerName,IPV4Address,ResponseTime 
    $connections = Invoke-Command -ComputerName $Computer -ScriptBlock {Test-Connection 1.1.2.2 -Count 2} | Select-Object PSComputerName,IPV4Address,ResponseTime 
}

# Site03
Elseif ($Computer -like "*site03*")
{
    Write-Host "Testing Site03 DNS connection..."
    $connections = Invoke-Command -ComputerName $Computer -ScriptBlock {Test-Connection 1.1.3.1 -Count 2} | Select-Object PSComputerName,IPV4Address,ResponseTime 
    $connections = Invoke-Command -ComputerName $Computer -ScriptBlock {Test-Connection 1.1.3.2 -Count 2} | Select-Object PSComputerName,IPV4Address,ResponseTime 
}

# Site04
Elseif ($Computer -like "*site04*")
{
    Write-Host "Testing Site04 DNS connection..."
    $connections = Invoke-Command -ComputerName $Computer -ScriptBlock {Test-Connection 1.1.4.1 -Count 2} | Select-Object PSComputerName,IPV4Address,ResponseTime 
    $connections = Invoke-Command -ComputerName $Computer -ScriptBlock {Test-Connection 1.1.4.2 -Count 2} | Select-Object PSComputerName,IPV4Address,ResponseTime 
}

Else
{
    Write-Host "Testing connection to an ESM server..."
    $connections = Invoke-Command -ComputerName $Computer -ScriptBlock {Test-Connection 208.67.222.222 -Count 2} | Select-Object PSComputerName,IPV4Address,ResponseTime 
}


    foreach ($connection in $connections) {      
        $props = @{'DNS IP Address'=$connection.IPV4Address;
                   'Response Time (ms)'=$connection.ResponseTime;
                  }
        New-Object -TypeName PSObject -Property $props 
    }
    }
foreach ($computer in $computername) {
    try {
        $everything_ok = $true
        Write-Verbose "Checking connectivity to $computer"
        Get-WmiObject -class Win32_BIOS -ComputerName $Computer -EA Stop | Out-Null
    } catch {
        Write-Warning "$computer failed"
        $everything_ok = $false
    }

    if ($everything_ok) {
        $filepath = Join-Path -Path $Path -ChildPath "$computer.html"

        $params = @{'As'='List';
                    'PreContent'='<h2>&diams; Operating System</h2>'}
        $html_os = Get-InfoOS -ComputerName $computer |
                   ConvertTo-EnhancedHTMLFragment @params 

                $params = @{'As'='List';
                    'PreContent'='<h2>&diams; Computer System</h2>'
                    'Properties'='Model',
                    'Manufacturer',
                    'RAM (GB)',
					'Processor',
                    'Sockets',
                    'Cores',
                    'Part of Domain',
                    'Domain Name'}
        
        $html_cs = Get-InfoCompSystem -ComputerName $computer |
                   ConvertTo-EnhancedHTMLFragment @params 
               
               
        $params = @{'As'='Table';
                    'PreContent'='<h2>&diams; Event Logs</h2>';
                    'EvenRowCssClass'='even';
                    'OddRowCssClass'='odd';
                    'MakeTableDynamic'=$true;
                    'TableCssClass'='grid'
					'Properties'='Computer Name',
					'Event ID',
					'Entry Type',
					'Message',
					'Time Written'}
        $html_el = Get-Events -ComputerName $Computer |
                   ConvertTo-EnhancedHTMLFragment @params

        $params = @{'As'='Table';
                    'PreContent'='<h2>&diams; Connection to OOB DNS</h2>';
                    'EvenRowCssClass'='even';
                    'OddRowCssClass'='odd';
                    'MakeTableDynamic'=$true;
                    'TableCssClass'='grid';}
        $html_ob = Get-Connections -ComputerName $Computer |
                   ConvertTo-EnhancedHTMLFragment @params

        $params = @{'As'='Table';
                    'PreContent'='<h2>&diams; Disk Space Report</h2>';
                    'EvenRowCssClass'='even';
                    'OddRowCssClass'='odd';
                    'MakeTableDynamic'=$true;
                    'TableCssClass'='grid';
                    'Properties'='Drive',
                    'Total Size (GB)',
                    'Free Space (GB)',
                    'Free Space (%)'}
                    
        $html_dr = Get-InfoDisk -ComputerName $computer |
                   ConvertTo-EnhancedHTMLFragment @params

        $params = @{'As'='Table';
                    'PreContent'='<h2>&diams; Top 15 Processes by Memory Used</h2>';
                    'EvenRowCssClass'='even';
                    'OddRowCssClass'='odd';
                    'MakeTableDynamic'=$true;
                    'TableCssClass'='grid'}
        $html_ip = Get-InfoProc -ComputerName $computer |
                   ConvertTo-EnhancedHTMLFragment @params 
        
        $params = @{'As'='Table';
                    'PreContent'='<h2>&diams; Persistent Routes</h2>';
                    'EvenRowCssClass'='even';
                    'OddRowCssClass'='odd';
                    'MakeTableDynamic'=$true;
                    'TableCssClass'='grid';}
        $html_pr = Get-PerRoutes -ComputerName $Computer |
                   ConvertTo-EnhancedHTMLFragment @params        

        $params = @{'As'= 'Table';
                    'PreContent'='<h2>&diams; Services in Stopped State That are Set to "Auto"</h2>';
                    'EvenRowCssClass'='even';
                    'OddRowCssClass'='odd';
                    'MakeTableDynamic'=$true;
                    'TableCssClass'='grid'}
        $html_sv = Get-InfoBadService -ComputerName $computer |
                   ConvertTo-EnhancedHTMLFragment @params 

        $params = @{'As'='Table';
                    'PreContent'='<h2>&diams; NIC Information</h2>';
                    'EvenRowCssClass'='even';
                    'OddRowCssClass'='odd';
                    'MakeTableDynamic'=$true;
                    'TableCssClass'='grid'
                    'Properties'='Adapter Label',
                    'IP Address',
                    'Subnet Mask',
                    'Default Gateway',
                    'MAC Address',
                    'Link Speed (Gbps)'}
        $html_na = Get-InfoNIC -ComputerName $Computer |
                   ConvertTo-EnhancedHTMLFragment @params
       
        $params = @{'As'='Table';
                    'PreContent'='<h2>&diams; Recently Installed Patches</h2>';
                    'EvenRowCssClass'='even';
                    'OddRowCssClass'='odd';
                    'MakeTableDynamic'=$true;
                    'TableCssClass'='grid'}
        $html_pa = Get-InstalledPatches -ComputerName $Computer |
                   ConvertTo-EnhancedHTMLFragment @params 

        $params = @{'CssStyleSheet'=$style;
                    'Title'="System Report for $computer";
                    'PreContent'="<h1>System Report for $computer</h1>";
                    'HTMLFragments'=@($html_os,$html_cs,$html_na,$html_pr,$html_ob,$html_dr,$html_ip,$html_sv,$html_pa,$html_el);
                    'jQueryDataTableUri'='C:\html\jquerydatatable.js';
                    'jQueryUri'='C:\html\jquery.js'}
        ConvertTo-EnhancedHTML @params |
        Out-File -FilePath $filepath
        #Invoke-Item -Path $filepath
        <#
        $params = @{'CssStyleSheet'=$style;
                    'Title'="System Report for $computer";
                    'PreContent'="<h1>System Report for $computer</h1>";
                    'HTMLFragments'=@($html_os,$html_cs,$html_dr,$html_pr,$html_sv,$html_na)}
        ConvertTo-EnhancedHTML @params |
        Out-File -FilePath $filepath
        #>
    }

    }
    }
    }
	Clear
    Get-Report
