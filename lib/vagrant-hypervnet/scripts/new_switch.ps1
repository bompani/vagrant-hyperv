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

 try {
   $switch = New-VMSwitch -Name $Name -SwitchType $SwitchType
 }
 catch {
   Write-ErrorMessage "Failed to create switch ${Name}: ${PSItem}"
   exit 1
 }

 if($IPAddress) {
   try {
      $vmAdapter = Get-VMNetworkAdapter -ManagementOS | Where-Object -Property SwitchId -EQ -Value  $switch.Id
      $adapter = Get-NetAdapter | Where-Object -Property DeviceId -EQ -Value $vmAdapter.DeviceId
      New-NetIPAddress -IPAddress $IPAddress -PrefixLength $PrefixLength -InterfaceIndex $adapter.ifIndex         
   }
   catch {
      Write-ErrorMessage "Failed to add IP address ${IPAddress} for switch ${Name}: ${PSItem}"
      exit 1            
   }
 }
   
Write-OutputMessage $($switch | Select-Object -Property Name, Id,
   @{Name='SwitchType';Expression={"$($_.SwitchType)"}},
   @{Name='NetAdapter';Expression={$switch_adapter[$_.Name]}} |
   ConvertTo-JSON)