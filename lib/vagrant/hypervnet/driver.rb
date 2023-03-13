require "json"
require "vagrant/util/powershell"

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
        switch = JSON.parse(output)
        if switch.kind_of?(Array)
          switch = switch[0]
        end
        switch
      end

      def find_switch_by_address(ip_address, prefix_length)        
        output = execute(:get_switch_by_address, DestinationPrefix: "#{ip_address}/#{prefix_length}")
        switch = JSON.parse(output)
        if switch.kind_of?(Array)
          switch = switch[0]
        end
        switch
      end

      def read_vm_mac_addresses
        output = execute(:get_vm_adapters, VMName: @vmName)
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
        output = execute(:get_vm_adapters, VMName: @vmName)
        data = JSON.parse(output)
        if data.kind_of?(Hash)
          data = Array(json)
        end

        adapters = []
        data.each do |value|
          adapter = {}
          adapter[:name] = value["Name"]
          adapter[:switch] = value["SwitchName"]
          adapter[:mac_address] = value["MacAddress"]
          adapters << adapter
        end
   
        adapters
      end

      def create_switch(type, name, ip_address = nil, prefix_length = nil)
        output = nul
        case type
        when :internal
          output = execute(:new_switch, Name: name, SwitchType: "Internal", IPAddress: ip_address, PrefixLength: prefix_length)
        when :private
          output = execute(:new_switch, Name: name, SwitchType: "Private")
        end

        JSON.parse(output)
      end

      def add_vm_adapter(switch)
        output = execute(:add_vm_adapter, VMName: @vmName, SwitchName: switch)
        data = JSON.parse(output)

        adapter = {}
        adapter[:name] = data["Name"]
        adapter[:switch] = data["SwitchName"]
        adapter[:mac_address] = data["MacAddress"]
   
        adapter        
      end

      def remove_vm_adapter(name)
        execute(:add_vm_adapter, VMName: @vmName, Name: name)        
      end

      def connect_vm_adapter(name, switch)
        execute(:connect_vm_adapter, VMName: @vmName, Name: name, SwitchName: switch)        
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
