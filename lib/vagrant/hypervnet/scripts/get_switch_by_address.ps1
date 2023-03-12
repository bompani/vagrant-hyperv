param (
    [parameter (Mandatory=$true)]
    [string]$DestinationPrefix
 )

$switches = @()

foreach($route in Get-NetRoute -DestinationPrefix $DestinationPrefix) {
    foreach($adapter in Get-NetAdapter -InterfaceIndex $route.ifIndex) {
        foreach($vmAdapter in Get-VMNetworkAdapter -ManagementOS | Where-Object -Property DeviceId -EQ -Value $adapter.DeviceId) {
            foreach($switch in Get-VMSwitch -Name $vmAdapter.SwitchName |
                Select-Object -Property Name,
                    @{Name='SwitchType';Expression={"$($_.SwitchType)"}},
                    @{Name='NetAdapter';Expression={$switch_adapter[$_.Name]}}) {
                      $switches += $switch
                    }
        }
    }
}

$switches | ConvertTo-Json