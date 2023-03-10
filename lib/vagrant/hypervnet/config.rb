require "vagrant"

module VagrantPlugins
  module HyperVNet
    class Config < Vagrant.plugin("2", :config)

      attr_reader :network_adapters

      def initialize        
        @network_adapters = {}

        network_adapter(1, :nat)
      end

      def network_adapter(slot, type, **opts)
        @network_adapters[slot] = [type, opts]
      end

      def finalize!
        @install_openssl = true if @install_openssl == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        machine.config.vm.networks.each do |type, data|
          if data[:hyperv__private] && type != :private_network
            errors << I18n.t("vagrant_hypervnet.private.private_on_bad_type")
            break
          end
        end

        {"Hyper-V network" => errors}
      end
    end
  end
end
