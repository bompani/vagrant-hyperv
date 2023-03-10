require 'vagrant-hypervnet/driver'

module VagrantPlugins
  module HyperVNet
    module Cap
      # Reads the network interface card MAC addresses and returns them.
      #
      # @return [Hash<String, String>] Adapter => MAC address
      def self.nic_mac_addresses(machine)
        driver = Driver.new(machine.provider_config.vmname)
        driver.read_vm_mac_addresses
      end
    end
  end
end
