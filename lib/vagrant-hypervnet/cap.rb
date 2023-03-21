require_relative 'driver'

module VagrantPlugins
  module HyperVNet
    module Cap
      # Reads the network interface card MAC addresses and returns them.
      #
      # @return [Hash<String, String>] Adapter => MAC address
      def self.nic_mac_addresses(machine)
        driver = Driver.new(machine.id)
        driver.read_vm_mac_addresses
      end
    end
  end
end
