# frozen_string_literal: true

begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant Hyper-V network plugin must be run within Vagrant."
end

I18n.load_path << File.expand_path("../../locales/en.yml",  __FILE__)
I18n.reload!

module VagrantPlugins
  module HyperVNet        
    class Plugin < Vagrant.plugin("2")
      name "Hyper-V network"
      description <<-DESC
        This plugin installs some extensions that allows Vagrant to manage
        network configuration of machines in Hyper-V.
        DESC

      config(:hypervnet) do
        require_relative "vagrant-hypervnet/config"
        Config
      end

      provider_capability(:hyperv, :nic_mac_addresses) do
        require_relative "vagrant-hypervnet/cap"
        Cap
      end

      guest_capability(:linux, :fix_net_config) do
        require_relative "vagrant-hypervnet/cap/linux/fix_net_config"
        Cap::Linux::FixNetConfig
      end

      action_hook(:hypervnet) do |hook|              
        require_relative 'vagrant-hypervnet/action'

        if defined?(VagrantPlugins::HyperV::Action::Configure)
          hook.before(VagrantPlugins::HyperV::Action::Configure, Action.disable_builtin_network_configure)
        end
        if defined?(VagrantPlugins::HyperV::Action::StartInstance)            
          hook.before(VagrantPlugins::HyperV::Action::StartInstance, Action.network)
        end
      end
    end
  end
end