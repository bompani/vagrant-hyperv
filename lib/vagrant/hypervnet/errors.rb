module VagrantPlugins
  module HyperVNet
    module Errors
      # A convenient superclass for all our errors.
      class HyperVNetError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_hypervnet.errors")
      end
    end
  end
end
