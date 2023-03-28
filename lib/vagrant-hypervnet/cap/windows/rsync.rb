require 'net/http'
require 'uri'

module VagrantPlugins
  module HyperVNet
    module Cap
      module Windows
        class RSync

          def self.rsync_installed(machine)
            machine.communicate.test("rsync -V")
          end

          def self.rsync_install(machine)
            if machine.config.hypervnet.install_rsync
              machine.ui.detail(I18n.t("vagrant_hypervnet.rsync.install")) 

              msys2_base_url = "https://repo.msys2.org/distrib/x86_64/"
              path_registry_key = "Registry::HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\Environment"
              msys2_url = Net::HTTP.get(URI.parse(msys2_base_url)).scan(/msys2-x86_64-\d+\.exe/)
                  .sort.map{|url| URI.join(msys2_base_url, url)}.last.to_s

              cmds = []
              cmds += [
                "Invoke-WebRequest -Uri '#{msys2_url}' -OutFile C:\\msys2.exe",
                "C:\\msys2.exe install --root 'C:\\MSYS2' --confirm-command",
                "C:\\msys2\\usr\\bin\\pacman -S rsync --noconfirm",
                "remove-item 'C:\\msys2.exe'"
              ]
              cmd = "$path = (Get-ItemProperty -Path '#{path_registry_key}' -Name path).path; "
              cmd << "$path = \"$path;C:\\MSYS2\\usr\\bin\"; "
              cmd << "Set-ItemProperty -Path '#{path_registry_key}' -Name path -Value $path"
              cmds << cmd

              machine.communicate.tap do |comm|
                cmds.each do |cmd|
                  comm.execute(cmd, shell: :powershell)
                end
              end

              if machine.guest.capability?(:sshd_reload)
                machine.guest.capability(:sshd_reload)
              end            
            end
          end

          def self.rsync_scrub_guestpath( machine, opts )
            if opts[:guestpath] =~ /^([a-zA-Z]):/
              opts[:guestpath].gsub( /^([a-zA-Z]):/, '/c/\1' )
            elsif !opts[:guestpath] =~ /^([a-zA-Z])\//
              "/c/#{opts[:guestpath]}"
            else
              opts[:guestpath] 
            end
          end
        end
      end
    end
  end
end
