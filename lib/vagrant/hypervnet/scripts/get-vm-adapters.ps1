param (
    [parameter (Mandatory=$true)]
    [string]$VMName
)

Get-VMNetworkAdapter -VMName $VMName | Select-Object -Property "SwitchName", "MacAddress" | ConvertTo-Json