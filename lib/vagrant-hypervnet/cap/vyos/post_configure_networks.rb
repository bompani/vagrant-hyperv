require "yaml"

module VagrantPlugins
  module HyperVNet
    module Cap
      module Vyos
        class PostConfigureNetworks  
          
          @@logger = Log4r::Logger.new("vagrant::hypervnet::guest::vyos::post_configure_networks")   

          def self.post_configure_networks(machine)
            nic_mac_addresses = machine.guest.capability(:nic_mac_addresses)
            machine.communicate.tap do |comm|
              commands = "#!/bin/vbash\n"
              commands << "if [ \"$(id -g -n)\" != 'vyattacfg' ] ; then\n"
              commands << "  exec sg vyattacfg -c \"/bin/vbash $(readlink -f $0) $@\"\n"
              commands << "fi\n"
              commands << "source /opt/vyatta/etc/functions/script-template\n"
              commands << "configure\n"

              nic_mac_addresses.each do |nic|
                commands << "set interfaces ethernet #{nic[:name]} hw-id '#{nic[:mac_address]}' \n"
              end
  
              commands << "commit\n"
              commands << "save\n"
              commands << "exit\n"

              @@logger.debug("Commands: \n#{commands}")

              temp = Tempfile.new("vagrant")
              temp.binmode
              temp.write(commands)
              temp.close
  
              comm.upload(temp.path, "/tmp/vagrant-configure-network")
              comm.execute("bash /tmp/vagrant-configure-network")
              comm.execute("rm -f /tmp/vagrant-configure-network")
            end
          end
        end
      end
    end
  end
end
