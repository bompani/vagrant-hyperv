#Requires -Modules VagrantMessages

param (
    [parameter (Mandatory=$true)]
    [string]$Name
 )

 $switches = @()

 try {
    foreach($switch in Get-VMSwitch | Where-Object -Property Name -EQ -Value  $Name |
        Select-Object -Property Name, Id,
            @{Name='SwitchType';Expression={"$($_.SwitchType)"}},
            @{Name='NetAdapter';Expression={$switch_adapter[$_.Name]}}) {
                $switches += $switch
            }
}
catch {
    Write-ErrorMessage "Failed to find switch by name ${Name}: ${PSItem}"
    exit 1            
}

Write-OutputMessage $(ConvertTo-JSON $switches)