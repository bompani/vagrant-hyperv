require "vagrant"

module VagrantPlugins
  module HyperVNet
    class Config < Vagrant.plugin("2", :config)

      attr_reader :network_adapters

      attr_accessor :install_ssh_server
      attr_accessor :install_rsync
      attr_accessor :default_switch

      def initialize        
        @network_adapters = []
        @install_ssh_server = UNSET_VALUE
        @install_rsync = UNSET_VALUE
        @default_switch = UNSET_VALUE
  
        network_adapter(:nat)
      end

      def network_adapter(type, **opts)
        @network_adapters <<  [type, opts]
      end

      def finalize!
        @install_ssh_server = true if @install_ssh_server == UNSET_VALUE
        @install_rsync = true if @install_rsync == UNSET_VALUE
        @default_switch = "Default Switch" if @default_switch == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        {"Hyper-V network" => errors}
      end
    end
  end
end
