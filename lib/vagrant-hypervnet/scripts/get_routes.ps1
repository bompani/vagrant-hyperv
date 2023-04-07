#Requires -Modules VagrantMessages

try {
    $routes = Get-NetRoute |  Select-Object -Property "DestinationPrefix"
}
catch {
    Write-ErrorMessage "Failed to get host routes: ${PSItem}"
    exit 1            
}

Write-OutputMessage $(ConvertTo-JSON $routes)