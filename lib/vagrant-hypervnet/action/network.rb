require "ipaddr"
require "log4r"
require "debug"

require "vagrant/util/scoped_hash_override"

require_relative "../driver"
require_relative "../errors"

module VagrantPlugins
  module HyperVNet    
    module Action
      class Network

        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::hypervnet::network")
        end

        def call(env)
          #binding.break
          @env = env
          @driver = Driver.new(env[:machine].provider_config.vmname)

          # Get the list of network adapters from the configuration
          network_adapters_config = env[:machine].config.hypervnet.network_adapters.dup

          @logger.info("Determining network adapters required for high-level configuration...")          
          env[:machine].config.vm.networks.each do |type, options|
            # We only handle private and public networks
            next if type != :private_network && type != :public_network

            options = scoped_hash_override(options, :hyperv)            

            # Internal network is a special type
            if type == :private_network && options[:private]
              type = :internal_network
            end

            if !options.key?(:type) && options.key?(:ip)
              begin
                addr = IPAddr.new(options[:ip])
                options[:type] = if addr.ipv4?
                                   :static
                                 else
                                   :static6
                                 end
              rescue IPAddr::Error => err
                raise Errors::NetworkAddressInvalid,
                      address: options[:ip], mask: options[:netmask],
                      error: err.message
              end
            end
            
            # Configure it
            data = nil
            if type == :private_network
              # private_network = internal
              data = [:internal, options]
            elsif type == :public_network
              # public_network = external
              data = [:external, options]
            elsif type == :internal_network
              # internal_network = private
              data = [:private, options]
            end
            
            # Store it!
            @logger.info(" -- Slot #{network_adapters_config.length}: #{data[0]}")
            network_adapters_config << data
          end

          @logger.info("Determining adapters and compiling network configuration...")
          adapters = []
          networks = []
          network_adapters_config.each.with_index(0) do |data, index|
            type    = data[0]
            options = data[1]

            @logger.info("Network #{index}. Type: #{type}.")

            # Get the normalized configuration for this type
            config = send("#{type}_config", options)
            @logger.debug("Normalized configuration: #{config.inspect}")

            # Get the Hyperv adapter configuration
            adapter = send("#{type}_adapter", config)
            adapters << adapter
            @logger.debug("Adapter configuration: #{adapter.inspect}")

             # Get the network configuration
            network = send("#{type}_network_config", config)
            network[:auto_config] = config[:auto_config]
            networks << network
          end

          if !adapters.empty?
            # Enable the adapters
            @logger.info("Enabling adapters...")
            env[:ui].output(I18n.t("vagrant_hypervnet.network.preparing"))
            adapters.each.with_index(0) do |adapter, index|
              @logger.info(adapter.inspect)
              env[:ui].detail(I18n.t(
                "vagrant_hypervnet.network_adapter",
                adapter: index.to_s,
                type: adapter[:type].to_s,
                switch: adapter[:switch].to_s
              ))
            end
            
            enable_adapters(adapters)
          end          

          # Continue the middleware chain.
          @app.call(env)

          # If we have networks to configure, then we configure it now, since
          # that requires the machine to be up and running.
          if !adapters.empty? && !networks.empty?
            assign_interface_numbers(networks, adapters)

            # Only configure the networks the user requested us to configure
            networks_to_configure = networks.select { |n| n[:auto_config] }
            if !networks_to_configure.empty?
              env[:ui].info I18n.t("vagrant_hypervnet.network.configuring")
              env[:machine].guest.capability(:configure_networks, networks_to_configure)
            end
          end                    
        end

        def external_config(options)
          return {
            auto_config:                     true,
            bridge:                          nil,
            mac:                             nil,
            use_dhcp_assigned_default_route: false
          }.merge(options || {})
        end

        def external_adapter(config)
          if config[:bridge]
            @logger.debug("Searching for bridge #{config[:bridge]}")

            chosen_bridge = @driver.find_switch_by_name(config[:bridge])
            if chosen_bridge
              @logger.info("Bridging adapter to #{chosen_bridge}")

              # Given the choice we can now define the adapter we're using
              return {
                type:        :external,
                switch:      chosen_bridge["Name"],
                mac_address: config[:mac]
              }
            else
              raise Errors::NetworkNotFound, name: config[:bridge]
            end
          else
            raise Errors::BridgeUndefinedInPublicNetwork
          end
        end

        def external_network_config(config)
          if config[:ip]
            options = {
                auto_config: true,
                mac:         nil,
                netmask:     "255.255.255.0",
                type:        :static
            }.merge(config)
            options[:type] = options[:type].to_sym
            return options
          end

          return {
            type: :dhcp,
            use_dhcp_assigned_default_route: config[:use_dhcp_assigned_default_route]
          }
        end

        def internal_config(options)
          return {
            auto_config:                     true,
            bridge:                          nil,
            mac:                             nil,
            netmask:                         "255.255.255.0",
            type:                            :static
          }.merge(options || {})
        end

        def internal_adapter(config)
          if config[:type].to_sym != :static
            raise Errors::NetworkTypeNotSupported, type: config[:type]
          elsif !config[:ip]
            raise Errors::IpUndefinedInPrivateNetwork
          end

          switch = nil
          netaddr = IPAddr.new(config[:ip]).mask(config[:netmask])            
          if config[:bridge]
            @logger.debug("Searching for switch #{config[:bridge]}")
            switch = @driver.find_switch_by_name(config[:bridge])            
          else
            @logger.info("Searching for matching switch: #{netaddr.to_s}")
            switch = @driver.find_switch_by_address(netaddr.to_s, netaddr.prefix)
          end

          if !switch
            @logger.info("Switch not found. Creating if we can.")
            if !config[:bridge]
              config[:bridge] = netaddr.to_s
            end

            # Create a new switch
            switch = @driver.create_switch(:internal, config[:bridge], netaddr.succ.to_s, netaddr.prefix)
            @logger.info("Created switch: #{switch[:name]}")
          end

          return {
            switch:      switch[:name],
            type:        :internal
          }
        end

        def internal_network_config(config)
          return {
            type:       config[:type],
            ip:         config[:ip],
            netmask:    config[:netmask]
          }
        end

        def private_config(options)
          return {
            type: "static",
            ip: nil,
            netmask: "255.255.255.0",
            auto_config: true
          }.merge(options || {})
        end

        def private_adapter(config)
          switch = nil
          if config[:bridge]
            @logger.debug("Searching for switch #{config[:bridge]}")
            switch = @driver.find_switch_by_name(config[:bridge])
         end

          if !switch
            @logger.info("Switch not found. Creating if we can.")

            # Create a new switch
            switch = @drive.create_switch(:private, config[:bridge])
            @logger.info("Created switch: #{switch[:name]}")
          end

          return {
            type:        :private,
            switch:      switch[:name],
          }
        end

        def private_network_config(config)
          return {
            type: config[:type],
            ip: config[:ip],
            netmask: config[:netmask]
          }
        end

        def nat_config(options)
          return options.merge(
            auto_config: false
          )
        end

        def nat_adapter(config)
          return {
            type:    :nat,
            switch:  "Default Switch"
          }
        end

        def nat_network_config(config)
          return {}
        end

        #-----------------------------------------------------------------
        # Misc. helpers
        #-----------------------------------------------------------------     
            
        def enable_adapters(adapters)
          vm_adapters = @driver.read_vm_network_adapters
          adapters.each do |adapter|           
            vm_adapter = vm_adapters.find{|vm_adapter|         
              !vm_adapter.has_key?(:switch) || vm_adapter[:switch] == adapter[:switch]}
            if !vm_adapter
              @logger.info("Adapter not found. Creating if we can.")
              vm_adapter = @driver.add_vm_adapter(adapter[:switch])              
              @logger.info("Created adapter: #{vm_adapter[:id]}")
            else
              vm_adapter[:switch] == adapter[:switch]
              vm_adapters.delete(vm_adapter)
            end
            @logger.info("Connecting adapter #{vm_adapter[:id]} to switch #{vm_adapter[:switch]}")
            @driver.connect_vm_adapter(vm_adapter[:id], vm_adapter[:switch])
          end

          vm_adapters.each do |vm_adapter|
            @logger.info("Removing adapter: #{vm_adapter[:id]}")
            @driver.remove_vm_adapter(vm_adapter[:id])
          end
        end

        # Assigns the actual interface number of a network based on the
        # enabled NICs on the virtual machine.
        #
        # This interface number is used by the guest to configure the
        # NIC on the guest VM.
        #
        # The networks are modified in place by adding an ":interface"
        # field to each.
        def assign_interface_numbers(networks, adapters)

          vm_adapters = @driver.read_vm_network_adapters
          vm_adapters.each.with_index(0) do |vm_adapter, index|
            vm_adapter[:interface] = index
          end

          adapters.each_index do |i|
            adapter = adapters[i]
            network = networks[i]
            vm_adapter = vm_adapters.find{|vm_adapter| vm_adapter[:switch] == adapter[:switch]}
            network[:interface] = vm_adapter[:interface]
          end
        end
      end
    end
  end
end