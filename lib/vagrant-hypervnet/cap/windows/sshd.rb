module VagrantPlugins
  module HyperVNet
    module Cap
      module Windows
        class Sshd

          def self.sshd_installed(machine)
            machine.communicate.test("Get-Service -Name sshd")
          end

          def self.sshd_install(machine)
            machine.communicate.sudo("Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'",
              shell: :powershell, elevated: true)

            ssh_key_url = "https://github.com/hashicorp/vagrant/raw/main/keys/vagrant.pub"
            ssh_key_path = "C:\\ProgramData\\ssh\\administrators_authorized_keys"

            cmds = []
            cmds += [
              "Invoke-WebRequest -Uri '#{ssh_key_url}' -OutFile '#{ssh_key_path}'",
              "icacls '#{ssh_key_path}' /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F'",
              "Start-Service sshd",
              "Set-Service -Name sshd -StartupType 'Automatic'"
            ]

            machine.communicate.tap do |comm|
              cmds.each do |cmd|
                comm.execute(cmd, shell: :powershell)
              end
            end

          end
        end
      end
    end
  end
end
