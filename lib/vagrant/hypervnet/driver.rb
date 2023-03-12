require "json"
require "log4r"
require "vagrant/util/powershell"
require_relative "plugin"

module VagrantPlugins
  module HyperVNet   
    class Driver
      ERROR_REGEXP  = /===Begin-Error===(.+?)===End-Error===/m
      OUTPUT_REGEXP = /===Begin-Output===(.+?)===End-Output===/m

      # @return [String] VM Name
      attr_reader :vmName

      def initialize(vmName)
        @vmName = vmName
        @logger = Log4r::Logger.new("vagrant::hypervnet::driver")
      end

      # Execute a PowerShell command and process the results
      #
      # @param [String] path Path to PowerShell script
      # @param [Hash] options Options to pass to command
      #
      # @return [Object, nil] If the command returned JSON content
      #                       it will be parsed and returned, otherwise
      #                       nil will be returned
      def execute(path, options={})
        if path.is_a?(Symbol)
          path = "#{path}.ps1"
        end
        r = execute_powershell(path, options)

        # We only want unix-style line endings within Vagrant
        r.stdout.gsub!("\r\n", "\n")
        r.stderr.gsub!("\r\n", "\n")

        error_match  = ERROR_REGEXP.match(r.stdout)
        output_match = OUTPUT_REGEXP.match(r.stdout)

        if error_match
          data = JSON.parse(error_match[1])

          # We have some error data.
          raise Errors::PowerShellError,
            script: path,
            stderr: data["error"]
        end

        if r.exit_code != 0
          raise Errors::PowerShellError,
            script: path,
            stderr: r.stderr
        end

        # Nothing
        return nil if !output_match
        return JSON.parse(output_match[1])
      end

      def find_switch_by_name(name)
        output = execute(:get_switch_by_name, Name: name)
        data = JSON.parse(output)
        if data.kind_of?(Hash)
          data = Array(json)
        elsif data.kind_of?(Array)
          data[0]
        else
          nil
        end
      end

      def find_switch_by_address(netaddr)        
        output = execute(:get_switch_by_address, DestinationPrefix: netaddr)
        data = JSON.parse(output)
        if data.kind_of?(Hash)
          data = Array(json)
        elsif data.kind_of?(Array)
          data[0]
        else
          nil
        end
      end

      def read_vm_mac_addresses
        output = execute(:get-vm_adapters, VMName: @vmName)
        data = JSON.parse(output)
        if data.kind_of?(Hash)
          data = Array(json)
        end
        
        adapters = {}
        data.each.with_index(1) do |value, index|
          adapters[index] = value["MacAddress"]
        end
   
        adapters
      end

      def read_vm_network_adapters
        output = execute(:get-vm_adapters, VMName: @vmName)
        data = JSON.parse(output)
        if data.kind_of?(Hash)
          data = Array(json)
        end

        adapters = []
        data.each do |value|
          adapter = {}
          adapter[:switch] = v["SwitchName"]
          adapter[:mac_address] = v["MacAddress"]
          adapters << adapter
        end
   
        adapters
      end

      def create_switch(type, name, ip = null, netmask = null)
        case type
        when :internal
          execute(:new_switch, Name: name, SwitchType: "Internal")
        when :private
          execute(:new_switch, Name: name, SwitchType: "Private")
        end
      end

      def enable_adapters(adapters)
        switches = read_switches
        adapters.each do |adapter|
          ipAddr = IPAddr.new adapter[:ip]
          subnet = ipAddr.mask adapter[:netmask]
          host = subnet.succ
          name = defined?(adapter[:name]) ? adapter[:name] : subnet.to_s

          @logger.debug("Configuring the VM network adapter of network: " +
            "Name: #{name} Subnet: #{subnet.to_s} Netmask: #{adapter[:netmask]} HostIP: #{host.to_s}")

          execute(:network_adapter, name: name, subnet: subnet, prefixLength: prefixLength,
            hostAddress: hostAddress,  nat: nat, vmName: @vmName)
        end
      end

      protected

      def execute_powershell(path, options, &block)
        lib_path = Pathname.new(File.expand_path("../scripts", __FILE__))
        mod_path = Vagrant::Util::Platform.wsl_to_windows_path(lib_path.join("utils")).to_s.gsub("/", "\\")
        path = Vagrant::Util::Platform.wsl_to_windows_path(lib_path.join(path)).to_s.gsub("/", "\\")
        options = options || {}
        ps_options = []
        options.each do |key, value|
          next if !value || value.to_s.empty?
          next if value == false
          ps_options << "-#{key}"
          # If the value is a TrueClass assume switch
          next if value == true
          ps_options << "'#{value}'"
        end

        # Always have a stop error action for failures
        ps_options << "-ErrorAction" << "Stop"

        # Include our module path so we can nicely load helper modules
        opts = {
          notify: [:stdout, :stderr, :stdin],
          module_path: mod_path
        }

        Vagrant::Util::PowerShell.execute(path, *ps_options, **opts, &block)
      end
    end
  end
end
