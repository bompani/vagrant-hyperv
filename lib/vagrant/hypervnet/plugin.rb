require 'vagrant-hypervnet/action'

module VagrantPlugins
    module HyperVNet        
        class Plugin < Vagrant.plugin("2")
            name "Hyper-V network configuration"
            description <<-DESC
                This plugin installs some extensions that allows Vagrant to manage
                network configuration of machines in Hyper-V.
                DESC

            config(:hypervnet) do
                require_relative "config"
                Config
            end

            provider_capability(:hyperv, :nic_mac_addresses) do
                require_relative "cap"
                Cap
              end

            action_hook(:hypervnet, :machine_action_start) do |hook|
                hook.before(VagrantPlugins::HyperV::Action::StartInstance, Action.network)
            end

            protected

            def self.init!
                return if defined?(@_init)
                I18n.load_path << File.expand_path("../../locales/en.yml",  __FILE__)
                I18n.reload!
                @_init = true
            end
        end
    end
end