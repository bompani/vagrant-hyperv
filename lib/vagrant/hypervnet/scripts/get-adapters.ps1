$adapter_address =  @{}

foreach($address in Get-NetIPAddress | Select-Object -Property "IPAddress", "InterfaceIndex", "PrefixLength") {
    $adapter_address[$address.InterfaceIndex] = $address
}

Get-NetAdapter |  Select-Object -Property "Name", @{Name='Status';Expression={"$($_.Status)"}},
    @{Name='IPAddress';Expression={$adapter_address[$_.ifIndex].IPAddress}},
    @{Name='PrefixLength';Expression={$adapter_address[$_.ifIndex].PrefixLength}},
    "ifIndex", "InterfaceGuid" | ConvertTo-Json