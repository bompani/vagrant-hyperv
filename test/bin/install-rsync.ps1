Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
Invoke-WebRequest -Uri 'https://github.com/hashicorp/vagrant/raw/main/keys/vagrant.pub' -OutFile C:\ProgramData\ssh\administrators_authorized_keys
icacls.exe C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F'
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

Invoke-WebRequest -Uri 'https://github.com/msys2/msys2-installer/releases/download/2023-01-27/msys2-x86_64-20230127.exe' -OutFile C:\msys2.exe
C:\msys2.exe install --root 'C:\MSYS2' --confirm-command
C:\msys2\usr\bin\pacman -S rsync --noconfirm
remove-item 'C:\msys2.exe'

$old = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name path).path
$new  =  "$old;C:\MSYS2\usr\bin"  
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name path -Value $new