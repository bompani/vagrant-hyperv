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

      guest_capability(:linux, :pre_configure_networks) do
        require_relative "vagrant-hypervnet/cap/linux/pre_configure_networks"
        Cap::Linux::PreConfigureNetworks
      end

      guest_capability(:vyos, :post_configure_networks) do
        require_relative "vagrant-hypervnet/cap/vyos/post_configure_networks"
        Cap::Vyos::PostConfigureNetworks
      end

      guest_capability(:linux, :nic_mac_addresses) do
        require_relative "vagrant-hypervnet/cap/linux/nic_mac_addresses"
        Cap::Linux::NicMacAddresses
      end      

      guest_capability(:windows, :rsync_installed) do        
        require_relative "vagrant-hypervnet/cap/windows/rsync"
        Cap::Windows::RSync
      end

      guest_capability(:windows, :rsync_install) do
        require_relative "vagrant-hypervnet/cap/windows/rsync"
        Cap::Windows::RSync
      end

      guest_capability(:windows, :sshd_installed) do        
        require_relative "vagrant-hypervnet/cap/windows/sshd"
        Cap::Windows::Sshd
      end

      guest_capability(:windows, :sshd_install) do
        require_relative "vagrant-hypervnet/cap/windows/sshd"
        Cap::Windows::Sshd
      end

      guest_capability(:windows, :sshd_reload) do
        require_relative "vagrant-hypervnet/cap/windows/sshd"
        Cap::Windows::Sshd
      end    

      action_hook(:hypervnet) do |hook|              
        require_relative 'vagrant-hypervnet/action'

        if defined?(VagrantPlugins::HyperV::Action::Configure)
          hook.before(VagrantPlugins::HyperV::Action::Configure, Action.disable_builtin_network_configure)
        end
        if defined?(VagrantPlugins::HyperV::Action::StartInstance)       
          hook.before(VagrantPlugins::HyperV::Action::StartInstance, Action.network)
        end
        hook.before(Vagrant::Action::Builtin::SyncedFolders, Action.ssh_server)
      end
    end
  end
end
