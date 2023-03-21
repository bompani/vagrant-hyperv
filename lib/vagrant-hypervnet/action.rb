require_relative 'action/disable_builtin_network_configure'
require_relative 'action/network'
require_relative 'action/ssh_server'

module VagrantPlugins
  module HyperVNet
    module Action
      include Vagrant::Action::Builtin

      def self.disable_builtin_network_configure
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use DisableBuiltinNetworkConfigure
        end
      end

      def self.network
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Network
        end
      end

      def self.ssh_server
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use SshServer
        end
      end
    end
  end
end
