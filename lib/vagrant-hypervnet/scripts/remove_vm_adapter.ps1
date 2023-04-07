param (
    [parameter (Mandatory=$true)]
    [string]$VmId,
    [parameter (Mandatory=$true)]
    [string]$Id
)

try {
    $vm = Get-VM -Id $VmId
    Get-VMNetworkAdapter -VM $vm | Where-Object -Property Id -EQ -Value $Id | Remove-VMNetworkAdapter
}
catch {
    Write-ErrorMessage "Failed to remove adapter ${Id} from VM ${VmId}: ${PSItem}"
    exit 1            
 }