require 'vagrant-hypervnet/action/network'

module VagrantPlugins
  module HyperVNet
    module Action
      include Vagrant::Action::Builtin

      def self.network
        Vagrant::Action::Builder.new.tap do |builder|
          builder.use ConfigValidate
          builder.use Network
        end
      end
    end
  end
end
