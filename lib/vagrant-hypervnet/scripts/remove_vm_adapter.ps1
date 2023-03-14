param (
    [parameter (Mandatory=$true)]
    [string]$VMName,
    [parameter (Mandatory=$true)]
    [string]$Name
)

Remove-VMNetworkAdapter -VMName $VMName -Name $Name