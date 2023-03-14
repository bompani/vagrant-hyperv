#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$VMName,
    [parameter (Mandatory=$true)]
    [string]$SwitchName 

)

$adapter = Add-VMNetworkAdapter -PassThru -VMName $VMName -SwitchName $SwitchName |
    Select-Object -Property "Name", "SwitchName", "MacAddress"

Write-OutputMessage $(ConvertTo-JSON $adapter)