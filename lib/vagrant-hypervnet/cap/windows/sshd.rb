
require 'vagrant/util/keypair'

module VagrantPlugins
  module HyperVNet
    module Cap
      module Windows
        class Sshd

          def self.sshd_installed(machine)
            machine.communicate.test("Get-Service -Name sshd")
          end

          def self.sshd_install(machine)
            machine.ui.detail(I18n.t("vagrant_hypervnet.ssh.install")) 

            machine.communicate.sudo("Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'",
              shell: :powershell, elevated: true)
              
            if machine.config.ssh.insert_key              
              insert = false
              ssh_info = machine.ssh_info
              if !ssh_info.nil?
                insert = ssh_info[:password] && ssh_info[:private_key_path].empty?
                ssh_info[:private_key_path].each do |pk|
                  if insecure_key?(pk)
                    insert = true
                    machine.ui.detail("\n"+I18n.t("vagrant_hypervnet.ssh.inserting_insecure_detected"))
                    break
                  end
                end
              end

              if insert
                _pub, priv, openssh = Vagrant::Util::Keypair.create  
                machine.ui.detail("\n"+I18n.t("vagrant_hypervnet.ssh.inserting_random_key"))
                insert_public_key(machine, openssh)
      
                # Write out the private key in the data dir so that the
                # machine automatically picks it up.
                machine.data_dir.join("private_key").open("w+") do |f|
                  f.write(priv)
                end

                # Adjust private key file permissions if host provides capability
                if machine.env.host.capability?(:set_ssh_key_permissions)
                  machine.env.host.capability(:set_ssh_key_permissions, machine.data_dir.join("private_key"))
                end
              
                # Remove the old key if it exists
                machine.ui.detail(I18n.t("vagrant_hypervnet.ssh.inserting_remove_key"))
                remove_public_key(machine, Vagrant.source_root.join("keys", "vagrant.pub").read.chomp)
      
                machine.ui.detail(I18n.t("vagrant_hypervnet.ssh.inserted_key")) 
              end
            end
            
            cmds = []
            cmds += [
              'Start-Service -Name sshd',
              'Set-Service -Name sshd -StartupType "Automatic"'
            ]

            machine.communicate.tap do |comm|
              cmds.each do |cmd|
                comm.execute(cmd, shell: :powershell)
              end
            end

          end

          def self.sshd_reload(machine)
            machine.ui.detail(I18n.t("vagrant_hypervnet.ssh.reload")) 
            machine.communicate.execute('Restart-Service -Name sshd', shell: :powershell)
          end

          def self.insecure_key?(path)
            return false if !path
            return false if !File.file?(path)
            source_path = Vagrant.source_root.join("keys", "vagrant")
            return File.read(path).chomp == source_path.read.chomp
          end

          def self.insert_public_key(machine, contents)
            contents = contents.strip
            winssh_modify_authorized_keys machine do |keys|
              if !keys.include?(contents)
                keys << contents
              end
            end
          end
  
          def self.remove_public_key(machine, contents)
            winssh_modify_authorized_keys machine do |keys|
              keys.delete(contents)
            end
          end
  
          def self.winssh_modify_authorized_keys(machine)
            comm = machine.communicate
            directories = fetch_guest_paths(comm)
            data_dir = directories[:data]
            temp_dir = directories[:temp]
  
            remote_ssh_dir = "#{data_dir}\\ssh"
            comm.execute("New-Item -Path '#{remote_ssh_dir}' -ItemType directory -Force", shell: "powershell")
            remote_upload_path = "#{temp_dir}\\vagrant-insert-pubkey-#{Time.now.to_i}"
            remote_authkeys_path = "#{remote_ssh_dir}\\administrators_authorized_keys"            
  
            keys_file = Tempfile.new("vagrant-windows-insert-public-key")
            keys_file.close
            # Check if an authorized_keys file already exists
            result = comm.execute("dir \"#{remote_authkeys_path}\"", shell: "cmd", error_check: false)
            if result == 0
              comm.download(remote_authkeys_path, keys_file.path)
              keys = File.read(keys_file.path).split(/[\r\n]+/)
            else
              keys = []
            end
            yield keys
            File.write(keys_file.path, keys.join("\r\n") + "\r\n")
            comm.upload(keys_file.path, remote_upload_path)
            keys_file.delete
            comm.execute(<<-EOC.gsub(/^\s*/, ""), shell: "powershell")
              Set-Acl "#{remote_upload_path}" (Get-Acl "#{remote_authkeys_path}")
              Move-Item -Force "#{remote_upload_path}" "#{remote_authkeys_path}"
            EOC
          end
  
          # Fetch user's temporary and data directory paths from the Windows guest
          #
          # @param [Communicator]
          # @return [Hash] {:temp, :data}
          def self.fetch_guest_paths(communicator)
            output = ""
            communicator.execute("Write-Output $env:TEMP\nWrite-Output $env:ProgramData", shell: "powershell") do |type, data|
              if type == :stdout
                output << data
              end
            end
            temp_dir, data_dir = output.strip.split(/[\r\n]+/)
            if temp_dir.nil? || data_dir.nil?
              raise Errors::PublicKeyDirectoryFailure
            end
            {temp: temp_dir, data: data_dir}
          end
        end
      end
    end
  end
end
