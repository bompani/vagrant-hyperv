#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$VmId
)

try{
    $vm = Get-VM -Id $VmId
    $adapter = Add-VMNetworkAdapter -PassThru -VM $vm |
        Select-Object -Property "Name", "Id"
}
catch {
    Write-ErrorMessage "Failed to add adapter to VM ${VmId}: ${PSItem}"
    exit 1            
 }

Write-OutputMessage $(ConvertTo-JSON $adapter)