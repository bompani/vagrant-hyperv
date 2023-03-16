#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$Name
 )

 $switches = Get-VMSwitch | Where-Object -Property Name -EQ -Value  $Name |
    Select-Object -Property Name,
        @{Name='SwitchType';Expression={"$($_.SwitchType)"}},
        @{Name='NetAdapter';Expression={$switch_adapter[$_.Name]}} 

Write-OutputMessage $(ConvertTo-JSON $switches)