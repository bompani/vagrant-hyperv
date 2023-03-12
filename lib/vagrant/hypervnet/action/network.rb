require "ipaddr"
require "log4r"

require "vagrant/util/network_ip"
require "vagrant/util/scoped_hash_override"

module VagrantPlugins
  module HyperVNet    
    module Action
      class Network

        # Default valid range for hostonly networks
        HOSTONLY_DEFAULT_RANGE = [IPAddr.new("192.168.56.0/21").freeze].freeze

        include Vagrant::Util::NetworkIP
        include Vagrant::Util::ScopedHashOverride

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::hypervnet::network")
        end

        def call(env)

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
                raise Vagrant::Errors::NetworkAddressInvalid,
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
            network_adapters_config[] << data
          end

          @logger.info("Determining adapters and compiling network configuration...")
          adapters = []
          networks = []
          network_adapters_config.each do |slot, data|
            type    = data[0]
            options = data[1]

            @logger.info("Network #{index}. Type: #{type}.")

            # Get the normalized configuration for this type
            config = send("#{type}_config", options)
            config[:adapter] = slot
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
            env[:ui].output(I18n.t("vagrant.actions.vm.network.preparing"))
            adapters.each do |adapter|
              env[:ui].detail(I18n.t(
                "hypervnet.network_adapter",
                adapter: adapter[:adapter].to_s,
                type: adapter[:type].to_s,
                extra: "",
              ))
            end
            
            @driver.enable_adapters(adapters)
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
              env[:ui].info I18n.t("vagrant.actions.vm.network.configuring")
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
              @logger.info("Bridging adapter #{config[:adapter]} to #{chosen_bridge}")

              # Given the choice we can now define the adapter we're using
              return {
                adapter:     config[:adapter],
                type:        :external,
                switch:      chosen_bridge["Name"],
                mac_address: config[:mac]
              }
            else
              raise Vagrant::Errors::NetworkNotFound, name: config[:bridge]
            end
          else
            raise Vagrant::Errors::BridgeUndefinedInPublicNetwork
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
          if config[type].to_sym != :static
            raise Vagrant::Errors::NetworkTypeNotSupported, type: config[type]
          elsif !config[:ip]
            raise Vagrant::Errors::IpUndefinedInPrivateNetwork
          end

          switch = nil
          if config[:bridge]
            @logger.debug("Searching for switch #{config[:bridge]}")
            switch = @driver.find_switch_by_name(config[:bridge])
          else
            netaddr = network_address(config[:ip], config[:netmask])
            @logger.info("Searching for matching switch: #{netaddr}")
            switch = find_switch_by_address(netaddr)
          end

          if !switch
            @logger.info("Switch not found. Creating if we can.")

            # Create a new switch
            switch = @driver.create_switch(:internal, config[:bridge], config[:ip], config[:netmask])
            @logger.info("Created switch: #{switch[:name]}")
          end

          return {
            adapter:     config[:adapter],
            switch:      switch[:name],
            mac_address: config[:mac],
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
            adapter: nil,
            mac: nil,
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
            adapter:      config[:adapter],
            type:        :private,
            mac_address: config[:mac],
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
            adapter: config[:adapter],
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
        # Assigns the actual interface number of a network based on the
        # enabled NICs on the virtual machine.
        #
        # This interface number is used by the guest to configure the
        # NIC on the guest VM.
        #
        # The networks are modified in place by adding an ":interface"
        # field to each.
        def assign_interface_numbers(networks, adapters)
          current = 0
          adapter_to_interface = {}

          # Make a first pass to assign interface numbers by adapter location
          vm_adapters = @env[:machine].provider.driver.read_network_interfaces
          vm_adapters.sort.each do |number, adapter|
            if adapter[:type] != :none
              # Not used, so assign the interface number and increment
              adapter_to_interface[number] = current
              current += 1
            end
          end

          # Make a pass through the adapters to assign the :interface
          # key to each network configuration.
          adapters.each_index do |i|
            adapter = adapters[i]
            network = networks[i]

            # Figure out the interface number by simple lookup
            network[:interface] = adapter_to_interface[adapter[:adapter]]
          end
        end
      end
    end
  end
end