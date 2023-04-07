#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$VmId
)

try {
    $vm = Get-VM -Id $VmId
    $adapters = Get-VMNetworkAdapter -VM $vm |
    Select-Object -Property "Name", "Id", "SwitchName", "SwitchId", "MacAddress"
}
catch {
    Write-ErrorMessage "Failed to get adapters of VM ${VmId}: ${PSItem}"
    exit 1            
}

Write-OutputMessage $(ConvertTo-JSON $adapters)