$i = '0'
$promptList = Read-Host "Path to server list"
$servername = Get-Content $promptList

while ($i = '0')
{
##### Script Starts Here ######

foreach ($Server in $ServerName) {

                if (test-Connection -ComputerName $Server -Count 2 -Quiet )
                
                        {
                        Write-Host "$Server is alive and Pinging " -ForegroundColor Green
                        }
                                        
                else
                                        
                        {
                        Write-Warning "$Server seems dead not pinging"
                        }        
}
Start-Sleep 2
Clear-Host                
}


##### Script Ends Here #####
