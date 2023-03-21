#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$VmId,
    [parameter (Mandatory=$true)]
    [string]$SwitchName 

)

$vm = Get-VM -Id $VmId
$adapter = Add-VMNetworkAdapter -PassThru -VM $vm -SwitchName $SwitchName |
    Select-Object -Property "Name", "Id", "SwitchName", "MacAddress"

Write-OutputMessage $(ConvertTo-JSON $adapter)