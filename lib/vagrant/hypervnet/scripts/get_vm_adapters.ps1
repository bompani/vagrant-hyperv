param (
    [parameter (Mandatory=$true)]
    [string]$VMName
)

Get-VMNetworkAdapter -VMName $VMName |
    Select-Object -Property "Name", "SwitchName", "MacAddress" | ConvertTo-Json