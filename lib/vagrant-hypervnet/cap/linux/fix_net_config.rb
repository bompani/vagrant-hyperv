require "yaml"

module VagrantPlugins
  module HyperVNet
    module Cap
      module Linux
        class FixNetConfig
          extend Vagrant::Util::GuestInspection::Linux    

          def self.fix_net_config(machine)
            if netplan?(machine.communicate)
              yaml = ""
              machine.communicate.sudo("netplan get 'ethernets'") do |type, data|
                yaml << data if type == :stdout
              end            
              ethernets = YAML.load(yaml)
              ethernets_to_fix = ethernets.select {|k,v| (v["dhcp4"] || v["dhcp6"]) && !v["critical"]}
              if !ethernets_to_fix.empty?
                ethernets_to_fix.each do |k,v|
                  machine.communicate.sudo("netplan set 'ethernets.#{k}.critical=true'")                   
                end
                machine.guest.capability(:reboot)                        
              end                       
            end
          end
        end
      end
    end
  end
end
