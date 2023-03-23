require "ipaddr"
require "log4r"

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
          @env = env
          @driver = Driver.new(env[:machine].id)

          network_adapters_config = env[:machine].config.hypervnet.network_adapters.dup

          @logger.info("Determining network adapters required for high-level configuration...")          
          env[:machine].config.vm.networks.each do |type, options|
            next if type != :private_network && type != :public_network

            options = scoped_hash_override(options, :hyperv)            

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
            
            data = nil
            if type == :private_network
              if options[:private]
                data = [:private, options]
              else
                data = [:internal, options]
              end
            elsif type == :public_network
              data = [:external, options]
            end
            
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

            config = send("#{type}_config", options)
            @logger.debug("Normalized configuration: #{config.inspect}")

            adapter = send("#{type}_adapter", config)
            adapters << adapter
            @logger.debug("Adapter configuration: #{adapter.inspect}")

            network = send("#{type}_network_config", config)
            network[:auto_config] = config[:auto_config]
            networks << network
          end

          if !adapters.empty?
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

          @app.call(env)

          if !adapters.empty? && !networks.empty?

            guest_adapters = {}
            if env[:machine].guest.capability?(:nic_mac_addresses)
              nic_mac_addresses = env[:machine].guest.capability(:nic_mac_addresses)
              @logger.info("Guest NIC MAC-addresses: #{nic_mac_addresses.inspect}")
              nic_mac_addresses.each.with_index(0) do |iface, index|
                guest_adapters[iface[:mac_address]] = index
              end
              @logger.info("Guest Adapters map: #{guest_adapters.inspect}")
            end

            assign_interface_numbers(networks, adapters, guest_adapters)

            networks_to_configure = networks.select { |n| n[:auto_config] }
            if !networks_to_configure.empty?
              env[:ui].info I18n.t("vagrant_hypervnet.network.configuring")

              networks_to_configure.each.with_index(0) do |network, index|
                @logger.info(network.inspect)
                env[:ui].detail(I18n.t(
                  "vagrant_hypervnet.network_config",
                  network: index.to_s,
                  interface: network[:interface].to_s,
                  type: network[:type].to_s,
                  ip: network[:ip].to_s,
                  netmask: network[:netmask].to_s
                ))
              end
              if env[:machine].guest.capability?(:fix_net_config)
                env[:machine].guest.capability(:fix_net_config)
              end
              env[:machine].guest.capability(:configure_networks, networks_to_configure)
            end
          end                    
        end

        def external_config(options)
          return {
            auto_config:                     true,
            bridge:                          nil,
            netmask:                         "255.255.255.0",
            type:                            :static
          }.merge(options || {})
        end

        def external_adapter(config)
          if config[:bridge]
            @logger.debug("Searching for bridge #{config[:bridge]}")

            switch = @driver.find_switch_by_name(config[:bridge])
            if switch
              @logger.info("Bridging adapter to #{switch[:name]}")

              return {
                type:        :external,
                switch:      switch[:name],
              }
            else
              raise Errors::NetworkNotFound, name: config[:bridge]
            end
          else
            raise Errors::BridgeUndefinedInPublicNetwork
          end
        end

        def external_network_config(config)
          return {
            type:       config[:type],
            ip:         config[:ip],
            netmask:    config[:netmask]
          }
        end

        def internal_config(options)
          return {
            auto_config:                     true,
            bridge:                          nil,
            netmask:                         "255.255.255.0",
            type:                            :static,
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
            auto_config:                     true,
            bridge:                          options[:private],
            netmask:                         "255.255.255.0",
            type:                            :static,
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
            switch = @driver.create_switch(:private, config[:bridge])
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
          adapters.each.with_index(0) do |adapter, index|   
            if index < vm_adapters.length
              vm_adapter = vm_adapters[index]
              @logger.info("Connecting adapter #{vm_adapter.inspect} to switch #{adapter[:switch]}")
              @driver.connect_vm_adapter(vm_adapter[:id], adapter[:switch])
            else
              vm_adapter = @driver.add_vm_adapter(adapter[:switch])              
              @logger.info("Created adapter: #{vm_adapter.inspect}")
            end
          end

          if vm_adapters.length > adapters.length
            for index in adapters.length .. vm_adapters.length-1 
              vm_adapter = vm_adapters[index]
              @logger.info("Removing adapter: #{vm_adapter.inspect}")
              @driver.remove_vm_adapter(vm_adapter[:id])
            end
          end
        end

        def assign_interface_numbers(networks, adapters, guest_adapters)
          vm_adapters = @driver.read_vm_network_adapters
          vm_adapters.each.with_index(0) do |vm_adapter, index|
            if guest_adapters && guest_adapters.key?(vm_adapter[:mac_address])
              networks[index][:interface] = guest_adapters[vm_adapter[:mac_address]]
            else
              networks[index][:interface] = index
            end
            @logger.info("Mapping vm adapter #{index} to guest adapter #{networks[index][:interface]}")
          end
        end
      end
    end
  end
end