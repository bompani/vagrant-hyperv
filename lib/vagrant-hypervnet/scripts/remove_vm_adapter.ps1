param (
    [parameter (Mandatory=$true)]
    [string]$VmId,
    [parameter (Mandatory=$true)]
    [string]$Id
)

$vm = Get-VM -Id $VmId
Get-VMNetworkAdapter -VM $vm | Where-Object -Property Id -EQ -Value $Id | Remove-VMNetworkAdapter