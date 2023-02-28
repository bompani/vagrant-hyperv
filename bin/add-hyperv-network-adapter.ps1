param (
    [parameter (Mandatory=$true)]
    [string]$name,
    [parameter (Mandatory=$true)]
    [string]$subnet,
    [parameter (Mandatory=$true)]
    [string]$prefixLength,
    [parameter (Mandatory=$true)]
    [string]$hostAddress,
    [parameter (Mandatory=$false)]
    [bool]$nat,
    [parameter (Mandatory=$true)]
    [string]$vmName
)

If ($name -in (Get-VMSwitch | Select-Object -ExpandProperty Name) -eq $FALSE) {
    'Creating Internal-only switch named ' + $name + ' on Windows Hyper-V host...'
    New-VMSwitch -SwitchName $name -SwitchType Internal        
}
else {
    'Switch ' + $name + ' already exists; skipping'
}

If ($hostAddress -in (Get-NetIPAddress | Select-Object -ExpandProperty IPAddress) -eq $FALSE) {
    'Registering new IP address ' + $hostAddress + ' on Windows Hyper-V host...'
    New-NetIPAddress -IPAddress $hostAddress -PrefixLength $prefixLength -InterfaceAlias ("vEthernet (" + $name + ")")
}
else {
    $hostAddress + ' for static IP configuration already registered; skipping'
}

if($nat) {
    $addressPrefix = ($subnet + '/' + $prefixLength)
    If ($addressPrefix -in (Get-NetNAT | Select-Object -ExpandProperty InternalIPInterfaceAddressPrefix) -eq $FALSE) {
        'Registering new NAT adapter for ' + $addressPrefix + ' on Windows Hyper-V host...'
        New-NetNAT -Name $name -InternalIPInterfaceAddressPrefix $addressPrefix
    }
    else {
        $addressPrefix + ' for static IP configuration already registered; skipping'
    }
}

If ($name -in (Get-VMNetworkAdapter -VMName $vmName -Name $name | Select-Object -ExpandProperty Name) -eq $FALSE) {
    'Creating network adapter named ' + $name + ' on Windows Hyper-V vm ' + $vmName
    Add-VMNetworkAdapter -VMName $vmName -SwitchName $name -Name $name
}
else {
    'NBetwork adapter ' + $name + ' already exists; skipping'
}

Connect-VMNetworkAdapter -VMName $vmName -SwitchName $name -Name $name
