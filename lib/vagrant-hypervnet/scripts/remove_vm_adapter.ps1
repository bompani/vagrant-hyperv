param (
    [parameter (Mandatory=$true)]
    [string]$VMName,
    [parameter (Mandatory=$true)]
    [string]$Id
)

Get-VMNetworkAdapter -VMName $VMName | Where-Object -Property Id -EQ -Value $Id | Remove-VMNetworkAdapter