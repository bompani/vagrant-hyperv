require "yaml"

module VagrantPlugins
  module HyperVNet
    module Cap
      module Linux
        class PreConfigureNetworks
          extend Vagrant::Util::GuestInspection::Linux    

          def self.pre_configure_networks(machine)
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
                machine.communicate.sudo("netplan apply &")
                machine.communicate.reset!                      
              end                       
            end
          end
        end
      end
    end
  end
end
