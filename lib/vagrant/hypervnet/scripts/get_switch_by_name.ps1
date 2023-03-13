param (
    [parameter (Mandatory=$true)]
    [string]$Name
 )

 Get-VMSwitch | Where-Object -Property Name -EQ -Value  $Name |
    Select-Object -Property Name,
        @{Name='SwitchType';Expression={"$($_.SwitchType)"}},
        @{Name='NetAdapter';Expression={$switch_adapter[$_.Name]}} |
    ConvertTo-Json