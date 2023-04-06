#Requires -Modules VagrantMessages

$routes = Get-NetRoute |  Select-Object -Property "DestinationPrefix"

Write-OutputMessage $(ConvertTo-JSON $routes)