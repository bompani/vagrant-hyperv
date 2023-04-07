param (
    [parameter (Mandatory=$true)]
    [string]$VmId,
    [parameter (Mandatory=$true)]
    [string]$Id,
    [parameter (Mandatory=$true)]
    [string]$SwitchId

)

try {
    $vm = Get-VM -Id $VmId
    $switch = Get-VMSwitch -Id $SwitchId
    Get-VMNetworkAdapter -VM $vm | Where-Object -Property Id -EQ -Value $Id | Connect-VMNetworkAdapter -VMSwitch $switch
}
catch {
    Write-ErrorMessage "Failed to connect adapter ${Id} of VM ${VmId} to switch ${SwitchId}: ${PSItem}"
    exit 1            
 }