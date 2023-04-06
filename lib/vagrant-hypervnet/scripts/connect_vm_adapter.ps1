param (
    [parameter (Mandatory=$true)]
    [string]$VmId,
    [parameter (Mandatory=$true)]
    [string]$Id,
    [parameter (Mandatory=$true)]
    [string]$SwitchId

)

$vm = Get-VM -Id $VmId
$switch = Get-VMSwitch -Id $SwitchId
Get-VMNetworkAdapter -VM $vm | Where-Object -Property Id -EQ -Value $Id | Connect-VMNetworkAdapter -VMSwitch $switch
