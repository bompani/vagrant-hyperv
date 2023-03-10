param(
  [parameter (Mandatory=$true)]
  [string]$adapterMAC,
  [parameter (Mandatory=$true)]
  [string]$address,
  [parameter (Mandatory=$true)]
  [string]$prefixLength
)

$adapter = $( Get-NetAdapter | Where-Object {$($_.MacAddress -replace "-","") -eq $adapterMAC}).Name
'Configuring network adapter ' + $adapter + ' [' + $adapterMAC + ']'

If ($null -eq ( Get-NetIPAddress -InterfaceAlias $adapter | Where-Object -Property 'IPAddress' -EQ -Value $address )) {
  'Removing old ip address on Windows Hyper-V vm interface ' + $adapter
  Get-NetIPAddress -InterfaceAlias $adapter | Remove-NetIPAddress -Confirm:$false

  'Creating ip address ' + $address +  ' on Windows Hyper-V vm interface ' + $adapter
  New-NetIPAddress -IPAddress $address -InterfaceAlias $adapter -PrefixLength $prefixLength
}