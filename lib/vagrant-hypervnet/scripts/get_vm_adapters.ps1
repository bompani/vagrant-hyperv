#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$VmId
)
$vm = Get-VM -Id $VmId
$adapters = Get-VMNetworkAdapter -VM $vm |
    Select-Object -Property "Name", "Id", "SwitchName", "MacAddress"

Write-OutputMessage $(ConvertTo-JSON $adapters)