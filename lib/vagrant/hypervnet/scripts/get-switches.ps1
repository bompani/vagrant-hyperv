$switch_adapter = @{}
$net_adapters = Get-NetAdapter
foreach($ethernet_port in Get-WmiObject -Namespace Root\Virtualization\V2 -Class Msvm_InternalEthernetPort){
    $endpoint_physical = Get-WmiObject -Namespace Root\Virtualization\V2 -Query "ASSOCIATORS OF {$ethernet_port} WHERE ResultClass=Msvm_LANEndpoint AssocClass=Msvm_EthernetDeviceSAPImplementation"
    $endpoint_virtual = Get-WmiObject -Namespace Root\Virtualization\V2 -Query "ASSOCIATORS OF {$endpoint_physical} where ResultClass=Msvm_LANEndpoint assocclass=Msvm_ActiveConnection"
    $ethernetswitchport = Get-WmiObject -Namespace Root\Virtualization\V2 -Query "ASSOCIATORS OF {$endpoint_virtual}  WHERE ResultClass=Msvm_EthernetSwitchPort AssocClass=Msvm_EthernetDeviceSAPImplementation"
    $vswitch = Get-WmiObject -Namespace Root\Virtualization\V2 -Query "ASSOCIATORS OF {$ethernetswitchport} WHERE ResultClass=Msvm_VirtualEthernetSwitch"

    $switch_adapter[$vswitch.ElementName] =
        ($net_adapters | Where-Object {($_).MacAddress -replace '-','' -eq $ethernet_port.PermanentAddress} |
            Select-Object -First 1 -Property @{Name='Adapter'; Expression={$_.Name}}).Adapter
}

Get-VMSwitch |  Select-Object -Property "Name", @{Name='SwitchType';Expression={"$($_.SwitchType)"}}, @{Name='NetAdapter';Expression={$switch_adapter[$_.Name]}}, "NetAdapterInterfaceGuid" |
    ConvertTo-Json