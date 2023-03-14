param (
    [parameter (Mandatory=$true)]
    [string]$VMName,
    [parameter (Mandatory=$true)]
    [string]$Id
)

$adapter = Get-VMNetworkAdapter -VMName $VMName | Where-Object -Property Id -EQ -Value $Id
Remove-VMNetworkAdapter -VMName $VMName -VMNetworkAdapter $adapter