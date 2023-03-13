param (
    [parameter (Mandatory=$true)]
    [string]$VMName,
    [parameter (Mandatory=$true)]
    [string]$Name,
    [parameter (Mandatory=$true)]
    [string]$SwitchName 

)

Connect-VMNetworkAdapter -VMName $VMName -Name $name -SwitchName $SwitchName |
    Select-Object -Property "Name", "SwitchName", "MacAddress" | ConvertTo-Json


Connect-VMNetworkAdapter