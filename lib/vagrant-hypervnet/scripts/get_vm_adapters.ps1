#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$VMName
)

$adapters = Get-VMNetworkAdapter -VMName $VMName |
    Select-Object -Property "Name", "Id", "SwitchName", "MacAddress"

Write-OutputMessage $(ConvertTo-JSON $adapters)