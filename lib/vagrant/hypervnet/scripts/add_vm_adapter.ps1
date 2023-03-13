param (
    [parameter (Mandatory=$true)]
    [string]$VMName,
    [parameter (Mandatory=$true)]
    [string]$SwitchName 

)

Add-VMNetworkAdapter -VMName $VMName -SwitchName $SwitchName |
    Select-Object -Property "Name", "SwitchName", "MacAddress" | ConvertTo-Json