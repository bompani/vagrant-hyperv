param (
    [parameter (Mandatory=$true)]
    [string]$VMName,
    [parameter (Mandatory=$true)]
    [string]$Id,
    [parameter (Mandatory=$true)]
    [string]$SwitchName 

)

Get-VMNetworkAdapter -VMName $VMName | Where-Object -Property Id -EQ -Value $Id | Connect-VMNetworkAdapter -SwitchName $SwitchName
