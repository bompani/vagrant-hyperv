param (
    [parameter (Mandatory=$true)]
    [string]$Name,
    [parameter (Mandatory=$true)]
    [string]$SwitchType

 )

 New-VMSwitch -Name $Name -SwitchType $SwitchType