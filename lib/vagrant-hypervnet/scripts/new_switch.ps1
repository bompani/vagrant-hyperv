#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$Name,
    [parameter (Mandatory=$true)]
    [string]$SwitchType,
    [parameter (Mandatory=$false)]
    [string]$IPAddress,
    [parameter (Mandatory=$false)]
    [string]$PrefixLength

 )

 $switch = New-VMSwitch -Name $Name -SwitchType $SwitchType

 if($IPAddress) {
    $vmAdapter = Get-VMNetworkAdapter -ManagementOS -SwitchName $switch.Name
    $adapter = Get-NetAdapter | Where-Object -Property DeviceId -EQ -Value $vmAdapter.DeviceId
    New-NetIPAddress -IPAddress $IPAddress -PrefixLength $PrefixLength -InterfaceIndex $adapter.ifIndex
 }
   
Write-OutputMessage $($switch | Select-Object -Property Name, Id,
   @{Name='SwitchType';Expression={"$($_.SwitchType)"}},
   @{Name='NetAdapter';Expression={$switch_adapter[$_.Name]}} |
   ConvertTo-JSON)