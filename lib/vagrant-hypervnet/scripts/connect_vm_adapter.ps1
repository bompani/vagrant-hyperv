param (
    [parameter (Mandatory=$true)]
    [string]$VmId,
    [parameter (Mandatory=$true)]
    [string]$Id,
    [parameter (Mandatory=$true)]
    [string]$SwitchName 

)

$vm = Get-VM -Id $VmId
Get-VMNetworkAdapter -VM $vm | Where-Object -Property Id -EQ -Value $Id | Connect-VMNetworkAdapter -SwitchName $SwitchName
