#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$DestinationPrefix
 )

$switches = @()

try {
    foreach($route in  Get-NetRoute | Where-Object -Property DestinationPrefix -EQ -Value $DestinationPrefix) {
        foreach($adapter in Get-NetAdapter -InterfaceIndex $route.ifIndex) {
            foreach($vmAdapter in Get-VMNetworkAdapter -ManagementOS | Where-Object -Property DeviceId -EQ -Value $adapter.DeviceId) {
                foreach($switch in Get-VMSwitch -Name $vmAdapter.SwitchName |
                    Select-Object -Property Name, Id,
                        @{Name='SwitchType';Expression={"$($_.SwitchType)"}},
                        @{Name='NetAdapter';Expression={$switch_adapter[$_.Name]}}) {
                        $switches += $switch
                        }
            }
        }
    }
}
catch {
    Write-ErrorMessage "Failed to find switch by IP ${DestinationPrefix}: ${PSItem}"
    exit 1            
}


Write-OutputMessage $(ConvertTo-JSON $switches)