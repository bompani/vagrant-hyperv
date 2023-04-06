#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$VmId
)

$vm = Get-VM -Id $VmId
$adapter = Add-VMNetworkAdapter -PassThru -VM $vm |
    Select-Object -Property "Name", "Id"

Write-OutputMessage $(ConvertTo-JSON $adapter)