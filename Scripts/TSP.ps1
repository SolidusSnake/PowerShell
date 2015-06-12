<#
Original module - http://www.powershelladmin.com/wiki/Ascii_art_characters_powershell_script

.PARAMETER InputText
String(s) to convert to ASCII.
.PARAMETER PrependChar
Optional. Makes the script prepend an apostrophe.
.PARAMETER Compression
Optional. Compress to five lines when possible, even when it causes incorrect
alignment of the letters g, y, p and q (and "¤").
.PARAMETER ForegroundColor
Optional. Console only. Changes text foreground color.
.PARAMETER BackgroundColor
Optional. Console only. Changes text background color.

#>

function Write-Ascii {
# Wrapping the script in a function to make it a module

[CmdLetBinding()]
param(
    [Parameter(ValueFromPipeline=$true, Mandatory=$true)][string[]] $InputText,
    [switch] $PrependChar,
    [switch] $Compression,
    [string] $ForegroundColor = 'Default',
    [string] $BackgroundColor = 'Default'
    #[int] $MaxChars = '25'
    )

begin {
    
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    
    # Algorithm from hell... This was painful. I hope there's a better way.
    function Get-Ascii {
    
        param([string] $Text)
    
        $LetterArray = [char[]] $Text.ToLower()
    
        #Write-Host -fore green $LetterArray
    
        # Find the letter with the most lines.
        $MaxLines = 0
        $LetterArray | ForEach-Object { if ($Letters.([string] $_).Lines -gt $MaxLines ) { $MaxLines = $Letters.([string] $_).Lines } }
    
        # Now this sure was a simple way of making sure all letter align tidily without changing a lot of code!
        if (-not $Compression) { $MaxLines = 6 }
    
        $LetterWidthArray = $LetterArray | ForEach-Object { $Letter = [string] $_; $Letters.$Letter.Width }
        $LetterLinesArray = $LetterArray | ForEach-Object { $Letter = [string] $_; $Letters.$Letter.Lines }
    
        #$LetterLinesArray
    
        $Lines = @{
            '1' = ''
            '2' = ''
            '3' = ''
            '4' = ''
            '5' = ''
            '6' = ''
        }
    
        #$LineLengths = @(0, 0, 0, 0, 0, 0)
    
        # Debug
        #Write-Host "MaxLines: $Maxlines"

        $LetterPos = 0
        foreach ($Letter in $LetterArray) {
        
            # We need to work with strings for indexing the hash by letter
            $Letter = [string] $Letter
        
            # Each ASCII letter can be from 4 to 6 lines.
        
            # If the letter has the maximum of 6 lines, populate hash with all lines.
            if ($LetterLinesArray[$LetterPos] -eq 6) {
            
                #Write-Host "Six letter letter"

                foreach ($Num in 1..6) {
                
                    $StringNum = [string] $Num
                
                    $LineFragment = [string](($Letters.$Letter.ASCII).Split("`n"))[$Num-1]
                
                    if ($LineFragment.Length -lt $Letters.$Letter.Width) {
                        $LineFragment += ' ' * ($Letters.$Letter.Width - $LineFragment.Length)
                    }
                
                    $Lines.$StringNum += $LineFragment
                
                }
            
            }
        
            # Add padding for line 6 for letters with 5 lines and populate lines 2-6.
            ## Changed to top-adjust 5-line letters if there are 6 total.
            ## Added XML properties for letter alignment. Most are "default", which is top-aligned.
            ## Also added script logic to handle it (2012-12-29): <fixation>bottom</fixation>
            elseif ($LetterLinesArray[$LetterPos] -eq 5) {
            
                #Write-Host "Five-letter letter"
            
                if ($MaxLines -lt 6 -or $Letters.$Letter.fixation -eq 'bottom') {
                
                    $Padding = ' ' * $LetterWidthArray[$LetterPos]
                    $Lines.'1' += $Padding
                
                    foreach ($Num in 2..6) {
                    
                        $StringNum = [string] $Num
                    
                        $LineFragment = [string](($Letters.$Letter.ASCII).Split("`n"))[$Num-2]
                    
                        if ($LineFragment.Length -lt $Letters.$Letter.Width) {
                            $LineFragment += ' ' * ($Letters.$Letter.Width - $LineFragment.Length)
                        }
                    
                        $Lines.$StringNum += $LineFragment
                    
                    }
                
                }
            
                else {
                
                    $Padding = ' ' * $LetterWidthArray[$LetterPos]
                    $Lines.'6' += $Padding
                
                    foreach ($Num in 1..5) {
                    
                        $StringNum = [string] $Num
                    
                        $LineFragment = [string](($Letters.$Letter.ASCII).Split("`n"))[$Num-1]
                    
                        if ($LineFragment.Length -lt $Letters.$Letter.Width) {
                            $LineFragment += ' ' * ($Letters.$Letter.Width - $LineFragment.Length)
                        }
                    
                        $Lines.$StringNum += $LineFragment
                    
                    }
                
                }
            
            }
        
            # Here we deal with letters with four lines.
            # Dynamic algorithm that places four-line letters on the bottom line if there are
            # 4 or 5 lines only in the letter with the most lines.
            else {
            
                #Write-Host "Four letter letter"

                # Default to putting the 4-liners at line 3-6
                $StartRange, $EndRange, $IndexSubtract = 3, 6, 3
                $Padding = ' ' * $LetterWidthArray[$LetterPos]
            
                # If there are 4 or 5 lines...
                if ($MaxLines -lt 6) {
                
                    $Lines.'2' += $Padding
                
                }
           
                # There are 6 lines maximum, put 4-line letters in the middle.
                else {
                
                    $Lines.'1' += $Padding
                    $Lines.'6' += $Padding
                    $StartRange, $EndRange, $IndexSubtract = 2, 5, 2
                
                }
            
                # There will always be at least four lines. Populate lines 2-5 or 3-6 in the hash.
                foreach ($Num in $StartRange..$EndRange) {
                
                    $StringNum = [string] $Num
                
                    $LineFragment = [string](($Letters.$Letter.ASCII).Split("`n"))[$Num-$IndexSubtract]
                
                    if ($LineFragment.Length -lt $Letters.$Letter.Width) {
                        $LineFragment += ' ' * ($Letters.$Letter.Width - $LineFragment.Length)
                    }
                
                    $Lines.$StringNum += $LineFragment
                
                }
            
            }
        
            $LetterPos++
        
        } # end of LetterArray foreach
    
        # Return stuff
        $Lines.GetEnumerator() | Sort Name | Select -ExpandProperty Value | ?{ $_ -match '\S' } | %{ if ($PrependChar) { "'" + $_ } else { $_ } }
    
    }

    # Populate the $Letters hashtable with character data from the XML.
    Function Get-LetterXML {
    
        #$LetterFile = Join-Path $PSScriptRoot 'letters.xml'
        #$Xml = [xml] (Get-Content $LetterFile)
        $xml = [xml]@'

<chars>
  <char>
    <name>a</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>7</width>
<data>  __ _
 / _` |
| (_| |
 \__,_|</data>
  </char>

  <char>
    <name>ä</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
<data> _   _
(_)_(_)
 / _` |
| (_| |
 \__,_|</data>
  </char>

  <char>
    <name>à</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
<data>  __
  \_\_
 / _` |
| (_| |
 \__,_|</data>
  </char>

  <char>
    <name>á</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
<data>   __
  /_/_
 / _` |
| (_| |
 \__,_|</data>
  </char>

  <char>
    <name>â</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
<data>  //\
 |/_\|
 / _` |
| (_| |
 \__,_|</data>
  </char>

  <char>
    <name>b</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
<data> _
| |__
| '_ \
| |_) |
|_.__/</data></char>


  <char>
    <name>c</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>6</width>
<data>  ___
 / __|
| (__
 \___|</data>
  </char>

  <char>
    <name>d</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
<data>     _
  __| |
 / _` |
| (_| |
 \__,_|</data></char>


  <char>
    <name>e</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>6</width>
<data>  ___
 / _ \
|  __/
 \___|</data>
 </char>

  <char>
    <name>é</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>6</width>
<data>   __
  /_/
 / _ \
|  __/
 \___|</data>
 </char>

   <char>
    <name>è</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>6</width>
<data>  __
  \_\
 / _ \
|  __/
 \___|</data>
 </char>

  <char>
    <name>ê</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>6</width>
<data>  //\
 |/_\|
 / _ \
|  __/
 \___|</data>
  </char>

  <char>
    <name>f</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>5</width>
<data>  __
 / _|
| |_
|  _|
|_|</data></char>


  <char>
    <name>g</name>
    <fixation>bottom</fixation>
    <lines>5</lines>
    <width>7</width>
<data>  __ _
 / _` |
| (_| |
 \__, |
 |___/</data></char>

  <char>
    <name>h</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
<data> _
| |__
| '_ \
| | | |
|_| |_|</data></char>

  <char>
    <name>i</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>3</width>
<data> _
(_)
| |
| |
|_|</data></char>

  <char>
    <name>j</name>
    <fixation>default</fixation>
    <lines>6</lines>
    <width>5</width>
<data>   _
  (_)
  | |
  | |
 _/ |
|__/</data></char>

  <char>
    <name>k</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>6</width>
<data> _
| | __
| |/ /
|   &lt;
|_|\_\</data></char>

  <char>
    <name>l</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>3</width>
<data> _
| |
| |
| |
|_|</data></char>

  <char>
    <name>m</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>11</width>
<data> _ __ ___
| '_ ` _ \
| | | | | |
|_| |_| |_|</data></char>


  <char>
    <name>n</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>7</width>
<data> _ __
| '_ \
| | | |
|_| |_|</data></char>


  <char>
    <name>o</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>7</width>
<data>  ___
 / _ \
| (_) |
 \___/</data></char>

  <char>
    <name>ö</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
    <data> _   _
(_)_(_)
 / _ \
| (_) |
 \___/</data>
  </char>


  <char>
    <name>ò</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
<data>  __
  \_\
 / _ \
| (_) |
 \___/</data>
  </char>

  <char>
    <name>ó</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
<data>   __
  /_/
 / _ \
| (_) |
 \___/</data>
  </char>

  <char>
    <name>ô</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
<data>  //\
 |/_\|
 / _ \
| (_) |
 \___/</data>
  </char>

  <char>
    <name>template</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>6</width>
<data></data>
  </char>

  <char>
    <name>p</name>
    <fixation>bottom</fixation>
    <lines>5</lines>
    <width>7</width>
<data> _ __
| '_ \
| |_) |
| .__/
|_|</data></char>
  
  <char>
    <name>q</name>
    <fixation>bottom</fixation>
    <lines>5</lines>
    <width>7</width>
<data>  __ _
 / _` |
| (_| |
 \__, |
    |_|</data>
  </char>
  
  <char>
    <name>r</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>6</width>
<data> _ __
| '__|
| |
|_|</data></char>


  <char>
    <name>s</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>5</width>
<data> ___
/ __|
\__ \
|___/</data></char>

  <char>
    <name>t</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>5</width>
<data> _
| |_
| __|
| |_
 \__|</data></char>


  <char>
    <name>u</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>7</width>
    <data> _   _
| | | |
| |_| |
 \__,_|</data>
  </char>
  
  <char>
    <name>ü</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
    <data> _   _
(_) (_)
| | | |
| |_| |
 \__,_|</data>
   </char>


  <char>
    <name>v</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>7</width>
<data>__   __
\ \ / /
 \ V /
  \_/</data>
  </char>


  <char>
    <name>w</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>10</width>
<data>__      __
\ \ /\ / /
 \ V  V /
  \_/\_/</data>
  </char>


  <char>
    <name>x</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>6</width>
<data>__  __
\ \/ /
 &gt;  &lt;
/_/\_\</data>
  </char>


  <char>
    <name>y</name>
    <lines>5</lines>
    <fixation>bottom</fixation>
    <width>7</width>
<data> _   _
| | | |
| |_| |
 \__, |
 |___/</data>
  </char>

    <char>
      <name>z</name>
      <fixation>default</fixation>
      <lines>4</lines>
      <width>5</width>
<data> ____
|_  /
 / /
/___|</data>
  </char>

  <char>
    <name>æ</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>10</width>
    <data>  __ ____
 / _`  _ \
| (_|  __/
 \__,____|</data>
   </char>


  <char>
    <name>ø</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>8</width>
<data>  ____
 / _//\
| (//) |
 \//__/</data>
    </char>
        
  <char>
    <name>å</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
<data>   __
  (())
 / _ '|
| (_| |
 \__,_|</data>
  </char>

  <char>
    <name>_</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>3</width>
    <data>&#xA0;&#xA0;&#xA0;
&#xA0;&#xA0;&#xA0;
&#xA0;&#xA0;&#xA0;
&#xA0;&#xA0;&#xA0;</data>
  </char>

  <char>
    <name>!</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>3</width>
<data> _
| |
| |
|_|
(_)</data>
  </char>
    
    <char>
      <name>?</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>5</width>
<data> ___
|__ \
  / /
 |_|
 (_)</data>
    </char>
    
    <char>
      <name>,</name>
      <fixation>default</fixation>
      <lines>4</lines>
      <width>3</width>
<data>
 _ 
( )
|/</data>
    </char>

    <char>
      <name>.</name>
      <fixation>default</fixation>
      <lines>4</lines>
      <width>3</width>
<data>   
   
 _ 
(_)</data>
    </char>

    <char>
      <name>-</name>
      <fixation>default</fixation>
      <lines>4</lines>
      <width>7</width>
<data>
 _____
|_____|
</data>
    </char>

    <char>
      <name>1</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>3</width>
<data> _
/ |
| |
| |
|_|</data>
    </char>
    
        <char>
      <name>2</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>7</width>
<data> ____
|___ \
  __) |
 / __/
|_____|</data>
    </char>
        
        <char>
      <name>3</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>7</width>
<data> _____
|___ /
  |_ \
 ___) |
|____/</data>
    </char>
    
        <char>
      <name>4</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>8</width>
<data> _  _
| || |
| || |_
|__   _|
   |_|</data>
    </char>
    
        <char>
      <name>5</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>7</width>
<data> ____
| ___|
|___ \
 ___) |
|____/</data>
    </char>

    <char>
      <name>6</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>7</width>
<data>  __
 / /_
| '_ \
| (_) |
 \___/</data>
    </char>
    
        <char>
      <name>7</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>7</width>
<data> _____
|___  |
   / /
  / /
 /_/</data>
    </char>
        
        <char>
      <name>8</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>7</width>
<data>  ___
 ( _ )
 / _ \
| (_) |
 \___/</data>
    </char>
        
<char>
      <name>9</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>7</width>
<data>  ___
 / _ \
| (_) |
 \__, |
   /_/</data>
    </char>
       
    <char>
      <name>0</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>7</width>
<data>  ___
 / _ \
| | | |
| |_| |
 \___/</data>
    </char>

    <char>
      <name>:</name>
      <fixation>default</fixation>
      <lines>4</lines>
      <width>3</width>
<data> _
(_)
 _
(_)</data>
    </char>

    <char>
      <name>;</name>
      <fixation>default</fixation>
      <lines>5</lines>
      <width>3</width>
<data> _
(_)
 _
( )
|/</data>
    </char>

  <char>
    <name>(</name>
    <fixation>default</fixation>
    <lines>6</lines>
    <width>5</width>
    <data>   __
  / /
 | |
 | |
 | |
  \_\</data>
  </char>

  <char>
    <name>)</name>
    <fixation>default</fixation>
    <lines>6</lines>
    <width>5</width>
    <data> __
 \ \
  | |
  | |
  | |
 /_/ </data>
  </char>

  <char>
    <name>&lt;</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>5</width>
    <data>   __
  / /
 / /
 \ \
  \_\</data>
  </char>

  <char>
    <name>&gt;</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>5</width>
    <data> __
 \ \
  \ \
  / /
 /_/ </data>
  </char>

  <char>
    <name>[</name>
    <fixation>default</fixation>
    <lines>6</lines>
    <width>5</width>
    <data>  __
 | _|
 | |
 | |
 | |
 |__|</data>
  </char>

  <char>
    <name>]</name>
    <fixation>default</fixation>
    <lines>6</lines>
    <width>5</width>
    <data>  __
 |_ |
  | |
  | |
  | |
 |__|</data>
  </char>

  <char>
    <name>{</name>
    <fixation>default</fixation>
    <lines>6</lines>
    <width>6</width>
    <data>    __
   / /
  | |
 &lt; &lt;
  | |
   \_\</data>
  </char>

  <char>
    <name>}</name>
    <fixation>default</fixation>
    <lines>6</lines>
    <width>6</width>
    <data> __
 \ \
  | |
   &gt; &gt;
  | |
 /_/  </data>
  </char>

  <char>
    <name>/</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
    <data>     __
    / /
   / /
  / /
 /_/   </data>
  </char>

  <char>
    <name>\</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>7</width>
    <data> __
 \ \
  \ \
   \ \
    \_\</data>
  </char>

  <char>
    <name>+</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>7</width>
    <data>   _
 _| |_
|_   _|
  |_|</data>
  </char>

  <char>
    <name>|</name>
    <fixation>default</fixation>
    <lines>6</lines>
    <width>3</width>
    <data> _
| |
| |
| |
| |
|_|</data>
  </char>

  <char>
    <name>`</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>3</width>
    <data> _
( )
 \|

</data>
  </char>

  <char>
    <name>'</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>3</width>
    <data> _
( )
|/

</data>
  </char>



  <char>
    <name>"</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>5</width>
    <data> _ _
( | )
 V V

</data>
  </char>
  
  <char>
    <name>¤</name>
    <lines>5</lines>
    <fixation>bottom</fixation>
    <width>7</width>
    <data>/\___/\
\  _  /
| (_) |
/ ___ \
\/   \/</data>
  </char>
  
  <char>
    <name>'</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>3</width>
    <data> _
( )
|/

</data>
  </char>

  <char>
    <name>*</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>6</width>
<data>__/\__
\    /
/_  _\
  \/</data>
  </char>


  <char>
    <name>^</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>4</width>
<data> /\
|/\|

</data>
  </char>


  <char>
    <name>$</name>
    <fixation>default</fixation>
    <lines>6</lines>
    <width>5</width>
<data>  _
 | |
/ __)
\__ \
(   /
 |_|</data>
  </char>

  <char>
    <name>=</name>
    <fixation>default</fixation>
    <lines>4</lines>
    <width>7</width>
<data> _____
|_____|
|_____|
</data>
  </char>
 
  <char>
    <name>£</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>8</width>
<data>   ___
  / ,_\
_| |_
 | |___
(_,____|</data>
  </char>
  
  <char>
    <name>@</name>
    <fixation>default</fixation>
    <lines>6</lines>
    <width>9</width>
<data>   ____
  / __ \
 / / _` |
| | (_| |
 \ \__,_|
  \____/</data>
  </char>

  <char>
    <name>#</name>
    <fixation>default</fixation>
    <lines>5</lines>
    <width>10</width>
<data>   _  _
 _| || |_
|_  ..  _|
|_      _|
  |_||_|</data>
  </char>


</chars>


'@

    
        $Xml.Chars.Char | ForEach-Object {
        
            $Letters.($_.Name) = New-Object PSObject -Property @{
            
                'Fixation' = $_.fixation
                'Lines'    = $_.lines
                'ASCII'    = $_.data
                'Width'    = $_.width
            
            }
        
        }
    
    }

    function Write-RainbowString {
    
        param([string] $Line,
              [string] $ForegroundColor = '',
              [string] $BackgroundColor = '')

        $Colors = @('Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow',
            'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow', 'White')


        # $Colors[(Get-Random -Min 0 -Max 16)]

        [char[]] $Line | %{
        
            if ($ForegroundColor -and $ForegroundColor -ieq 'rainbow') {
            
                if ($BackgroundColor -and $BackgroundColor -ieq 'rainbow') {
                    Write-Host -ForegroundColor $Colors[(Get-Random -Min 0 -Max 16)] `
                        -BackgroundColor $Colors[(Get-Random -Min 0 -Max 16)] -NoNewline $_
                }
                elseif ($BackgroundColor) {
                    Write-Host -ForegroundColor $Colors[(Get-Random -Min 0 -Max 16)] `
                        -BackgroundColor $BackgroundColor -NoNewline $_
                }
                else {
                    Write-Host -ForegroundColor $Colors[(Get-Random -Min 0 -Max 16)] -NoNewline $_
                }

            }
            # One of them has to be a rainbow, so we know the background is a rainbow here...
            else {
            
                if ($ForegroundColor) {
                    Write-Host -ForegroundColor $ForegroundColor -BackgroundColor $Colors[(Get-Random -Min 0 -Max 16)] -NoNewline $_
                }
                else {
                    Write-Host -BackgroundColor $Colors[(Get-Random -Min 0 -Max 16)] -NoNewline $_
                }
            }

        }
    
        Write-Host ''
    
    }

    # Get ASCII art letters/characters and data from XML. Make it persistent for the module.
    if (-not (Get-Variable -EA SilentlyContinue -Scope Script -Name Letters)) {
        $script:Letters = @{}
        Get-LetterXML
    }

    # Turn the [string[]] into a [string] the only way I could figure out how... wtf
    #$Text = ''
    #$InputText | ForEach-Object { $Text += "$_ " }

    # Limit to 30 characters
    #$MaxChars = 30
    #if ($Text.Length -gt $MaxChars) { "Too long text. There's a maximum of $MaxChars characters."; return }

    # Replace spaces with underscores (that's what's used for spaces in the XML).
    #$Text = $Text -replace ' ', '_'

    # Define accepted characters (which are found in XML).
    #$AcceptedChars = '[^a-z0-9 _,!?./;:<>()¤{}\[\]\|\^=\$\-''+`\\"æøåâàáéèêóòôü]' # Some chars only works when sent as UTF-8 on IRC
    $LetterArray = [string[]]($Letters.GetEnumerator() | Sort Name | Select -ExpandProperty Name)
    $AcceptedChars = [regex] ( '(?i)[^' + ([regex]::Escape(($LetterArray -join '')) -replace '-', '\-' -replace '\]', '\]') + ' ]' )
    # Debug
    #Write-Host -fore cyan $AcceptedChars.ToString()
}

process {
    if ($InputText -match $AcceptedChars) { "Unsupported character, using these accepted characters: " + ($LetterArray -join ', ') + "."; return }

    # Filthy workaround (now worked around in the foreach creating the string).
    #if ($Text.Length -eq 1) { $Text += '_' }

    $Lines = @()

    foreach ($Text in $InputText) {
        
        $ASCII = Get-Ascii ($Text -replace ' ', '_')

        if ($ForegroundColor -ne 'Default' -and $BackgroundColor -ne 'Default') {
            if ($ForegroundColor -ieq 'rainbow' -or $BackGroundColor -ieq 'rainbow') {
                $ASCII | ForEach-Object { Write-RainbowString -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -Line $_ }
            }
            else {
                Write-Host -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor ($ASCII -join "`n")
            }
        }
        elseif ($ForegroundColor -ne 'Default') {
            if ($ForegroundColor -ieq 'rainbow') {
                $ASCII | ForEach-Object { Write-RainbowString -ForegroundColor $ForegroundColor -Line $_ }
            }
            else {    
                Write-Host -ForegroundColor $ForegroundColor ($ASCII -join "`n")
            }
        }
        elseif ($BackgroundColor -ne 'Default') {
            if ($BackgroundColor -ieq 'rainbow') {
                $ASCII | ForEach-Object { Write-RainbowString -BackgroundColor $BackgroundColor -Line $_ }
            }    
            else {
                Write-Host -BackgroundColor $BackgroundColor ($ASCII -join "`n")
            }
        }
        else { $ASCII -replace '\s+$' }

    } # end of foreach

} # end of process block
    
}


Clear

$pshost = get-host
$pswindow = $pshost.ui.rawui
$pswindow.WindowTitle = "Troubleshooting Pack Version 1.0"
#$newsize = $pswindow.buffersize
#$newsize.height = 3000
#$newsize.width = 150
#$pswindow.buffersize = $newsize

#$newsize = $pswindow.windowsize
#$newsize.height = 50
#$newsize.width = 115
#$pswindow.windowsize = $newsize


Write-Host "
Troubleshooting Pack Version 1.0.`n" -ForegroundColor Yellow

Write-Host "Brought to you by`n" -ForegroundColor Yellow
Write-Ascii -InputText "The Windows Team" -ForegroundColor rainbow -BackgroundColor black

Write-Host "`nThis tool was designed to help you, the System Administrator, be able to rule
out very common issues that should be apart of your troubleshooting steps.
This tool is still a WIP, but should be enough to get you started.  Enjoy!`n`n" -ForegroundColor Red
Sleep -Seconds 5
$localuser = $env:UserName
$userprompt = $localuser.split('.')[0]
Write-Host "Good day, Sir"$userprompt"." -ForegroundColor Green
$server = $env:computername
$filepath = Read-Host "Where do you want to save the output? [EX: C:\diag.txt]"
$Activity = "Troubleshooting Pack running..."

#Get Warning/Error Information from specified Log and To and From Times
$evtOutput =
"************************************************************
*                     Checking event logs                  *
************************************************************"

$evtOutput | Out-File $filepath
$logcheck = Read-Host "Do you want to check event logs?
[Y]es or [N]o"
Clear
If ($logcheck -eq "Y")
{
    Write-Progress -Activity $Activity -Status "Checking event logs [STEP 1/10]" -PercentComplete (1/10*100)
    Write-Host "Event log 'Errors' and 'Warnings' for the log you specify"
    $Log = Read-Host "What Log do you want information from? (System, Application, or Security)"
    $EvtStart = Read-Host "Start Time Requested (MM/DD/YYYY HH:MM AM/PM)"
    $EvtEnd = Read-Host "End Time Reqested (MM/DD/YYYY HH:MM AM/PM)"

    Get-EventLog $log -After "$EvtStart" -Before "$EvtEnd" -EntryType Error,Warning | Format-Table -AutoSize | Out-String | Out-File $filepath -Append

    $logcheck2 = Read-Host "Do you want to check any more logs?
    [Y]es or [N]o"
    If ($logcheck2 -eq "Y")
        {
            Write-Host "Event log 'Errors' and 'Warnings' for the log you specify"
            $Log = Read-Host "What Log do you want information from? (System, Application, or Security)"
            $EvtStart = Read-Host "Start Time Requested (MM/DD/YYYY HH:MM AM/PM)"
            $EvtEnd = Read-Host "End Time Reqested (MM/DD/YYYY HH:MM AM/PM)"

            Get-EventLog $log -After "$EvtStart" -Before "$EvtEnd" -EntryType Error,Warning | Format-Table -AutoSize | Out-String | Out-File $filepath -Append
        }
}
Else
{
    "!!! Event logs skipped !!!" | Out-File $filepath -Append
    Write-Progress -Activity $Activity -Status "Skipping event logs [STEP 1/10]" -PercentComplete (1/10*100)
}
Sleep -Seconds 5

# Ping OOB DNS
$dnsOutput =
"************************************************************
*               Checking OOB DNS Connections               *
************************************************************"

Write-Progress -Activity $Activity -Status "Checking OOB DNS connections [STEP 2/10]" -PercentComplete (2/10*100)
# Oklahoma City
If ($server -like "*site01*")
{
    $dnsOutput | Out-File $filepath -Append
    Test-Connection x.x.x.1 -Count 2 | Select-Object PSComputerName,IPV4Address,ResponseTime | Out-File $filepath -Append
    Test-Connection x.x.x.2 -Count 2 | Select-Object PSComputerName,IPV4Address,ResponseTime | Out-File $filepath -Append
}

# St. Louis
Elseif ($server -like "*site02*")
{
    $dnsOutput | Out-File $filepath -Append
    Test-Connection x.x.y.1 -Count 2 | Select-Object PSComputerName,IPV4Address,ResponseTime | Out-File $filepath -Append
    Test-Connection x.x.y.2 -Count 2 | Select-Object PSComputerName,IPV4Address,ResponseTime | Out-File $filepath -Append
}

# Columbus
Elseif ($server -like "*site03*")
{
    $dnsOutput | Out-File $filepath -Append
    Test-Connection x.x.z.1 -Count 2 | Select-Object PSComputerName,IPV4Address,ResponseTime | Out-File $filepath -Append
    Test-Connection x.x.z.2 -Count 2 | Select-Object PSComputerName,IPV4Address,ResponseTime | Out-File $filepath -Append
}

# San Antonio
Elseif ($server -like "*site04*")
{
    $dnsOutput | Out-File $filepath -Append
    Test-Connection x.y.y.1 -Count 2 | Select-Object PSComputerName,IPV4Address,ResponseTime | Out-File $filepath -Append
    Test-Connection x.y.y.2 -Count 2 | Select-Object PSComputerName,IPV4Address,ResponseTime | Out-File $filepath -Append
}

Else
{
    $dnsOutput | Out-File $filepath -Append
    Test-Connection a.b.c.d -Count 2 | Select-Object PSComputerName,IPV4Address,ResponseTime | Out-File $filepath -Append
}
Sleep -Seconds 2

#Check Routes
$rtOutput = 
"************************************************************
*                Checking persistent routes                *
************************************************************"

Write-Progress -Activity $Activity -Status "Checking persistent routes [STEP 3/10]" -PercentComplete (3/10*100)
$rtOutput | Out-File $filepath -Append
Get-WmiObject Win32_IP4persistedroutetable | Select-Object @{l='Hostname';e={$_.PSComputerName}},@{l='Network Address';e={$_.Name}},Mask,@{l='Gateway Address';e={$_.NextHop}},Metric1 | Format-Table -AutoSize | Out-String | Out-File $filepath -Append
Sleep -Seconds 2

#See What Patches have been Installed
$hfOutput = 
"************************************************************
*            Listing recently installed patches            *
************************************************************"

Write-Progress -Activity $Activity -Status "Listing last 15 installed patches [STEP 4/10]" -PercentComplete (4/10*100)
$hfOutput | Out-File $filepath -Append
Get-HotFix | Sort-Object -Descending InstalledOn | select HotFixID, InstalledOn, InstalledBy -First 15 | Format-Table -AutoSize | Out-String | Out-File $filepath -Append
Sleep -Seconds 2

#Top Process and Memory Used
$procOutput = 
"************************************************************
*         Showing top 15 processes by memory usage         *
************************************************************"

Write-Progress -Activity $Activity -Status "Showing top 15 processes by memory usage [STEP 5/10]" -PercentComplete (5/10*100)
$procOutput | Out-File $filepath -Append
Get-Process | Sort-Object -Descending WS | Format-Table Name,ID,@{l='Memory (MB)';e={$_.workingset / 1MB -as [int]}} | Select-Object -First 15 | Out-String | Out-File $filepath -Append
Sleep -Seconds 2

#Services in Stopped State that are set to Automatic
$srvOutput = 
"************************************************************
*    Checking stopped services with startup type 'AUTO'    *
************************************************************"

Write-Progress -Activity $Activity -Status "Checking for stopped services set to 'AUTO' [STEP 6/10]" -PercentComplete (6/10*100)
$srvOutput | Out-File $filepath -Append
Get-WmiObject -Query "Select __Server,Name,DisplayName,State,StartMode,ExitCode,Status FROM Win32_Service WHERE StartMode='Auto' AND State!='Running'" | Format-Table -AutoSize | Out-String | Out-File $filepath -Append
Sleep -Seconds 2

#Get Disk Space Report
$diskOutput = 
"************************************************************
*                   Checking drive space                   *
************************************************************"

Write-Progress -Activity $Activity -Status "Checking drive space [STEP 7/10]" -PercentComplete (7/10*100)
$diskOutput | Out-File $filepath -Append
Get-WmiObject Win32_logicaldisk -Filter "DriveType = 3" | Format-Table @{l='Drive';e={$_.deviceid}},@{l='Freespace (GB)';e={$_.freespace / 1GB -as [int]}} -autosize | Out-String | Out-File $filepath -Append
Sleep -Seconds 2

#Netstat
$netOutput = 
"************************************************************
*                Listing TCP/IP connections                *
************************************************************"

Write-Progress -Activity $Activity -Status "Checking for 'LISTENING' connections [STEP 8/10]" -PercentComplete (8/10*100)
$netOutput | Out-File $filepath -Append
netstat -ano | Select-String "LISTENING" | Out-String | Out-File $filepath -Append
Sleep -Seconds 2

Write-Progress -Activity $Activity -Status "Checking for 'ESTABLISHED' connections [STEP 9/10]" -PercentComplete (9/10*100)
netstat -ano | Select-String "ESTABLISHED" | Out-String | Out-File $filepath -Append
Sleep -Seconds 2

Write-Progress -Activity $Activity -Status "COMPLETED" -PercentComplete (10/10*100)
"***COMPLETED ***" | Out-File $filepath -Append
