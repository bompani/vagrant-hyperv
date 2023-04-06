module VagrantPlugins
  module HyperVNet
    module Errors
      # A convenient superclass for all our errors.
      class HyperVNetError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_hypervnet.errors")
      end

      class BridgeUndefinedInPublicNetwork < HyperVNetError
        error_key(:bridge_undefined_in_public_network)
      end

      class IpUndefinedInPrivateNetwork < HyperVNetError
        error_key(:ip_undefined_in_private_network)
      end

      class PowerShellError < HyperVNetError
        error_key(:powershell_error)
      end

      class NetworkAddressInvalid < HyperVNetError
        error_key(:network_address_invalid)
      end

      class NetworkAddressOverlapping < HyperVNetError
        error_key(:network_address_overlapping)
      end      

      class NetworkNotUnique < HyperVNetError
        error_key(:network_not_unique)
      end      

      class NetworkNotFound < HyperVNetError
        error_key(:network_not_found)
      end

      class NetworkTypeNotSupported < HyperVNetError
        error_key(:network_type_not_supported)
      end  
    end
  end
end
