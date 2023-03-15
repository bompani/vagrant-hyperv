require "json"
require "vagrant/util/powershell"

require_relative "errors"

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

          @logger.info("Error in #{path}: #{data["error"]}")
          # We have some error data.
          raise Errors::PowerShellError,
            script: path,
            stderr: data["error"]
        end

        if r.exit_code != 0
          @logger.info("Error in #{path}: #{r.stderr}")
          raise Errors::PowerShellError,
            script: path,
            stderr: r.stderr
        end

        # Nothing
        return nil if !output_match
        return JSON.parse(output_match[1])
      end

      def find_switch_by_name(name)
        data = execute(:get_switch_by_name, Name: name)
        if data && data.kind_of?(Array)
          data = data[0]
        end

        if data
          switch = {}
          switch[:name] = data["Name"]          
          switch[:type] = data["SwitchType"]
        end

        switch
      end

      def find_switch_by_address(ip_address, prefix_length)        
        data = execute(:get_switch_by_address, DestinationPrefix: "#{ip_address}/#{prefix_length}")
        if data && data.kind_of?(Array)
          data = data[0]
        end

        if data
          switch = {}
          switch[:name] = data["Name"]          
          switch[:type] = data["SwitchType"]
        end

        switch
      end

      def read_vm_mac_addresses
        adapters = {}

        data = execute(:get_vm_adapters, VMName: @vmName)
        if data
          if data.kind_of?(Hash)
            data = [] << data
          end
          
          data.each.with_index(1) do |value, index|
            adapters[index] = value["MacAddress"]
          end
        end

        adapters
      end

      def read_vm_network_adapters
        adapters = []

        data = execute(:get_vm_adapters, VMName: @vmName)
        if data
          if data.kind_of?(Hash)
            data = [] << data
          end   
          data.each do |value|
            adapter = {}
            adapter[:id] = value["Id"]
            adapter[:name] = value["Name"]
            adapter[:switch] = value["SwitchName"]
            adapter[:mac_address] = value["MacAddress"]
            adapters << adapter
          end
        end        
        adapters
      end

      def create_switch(type, name, ip_address = nil, prefix_length = nil)
        case type
        when :internal
          data = execute(:new_switch, Name: name, SwitchType: "Internal", IPAddress: ip_address, PrefixLength: prefix_length)
        when :private
          data = execute(:new_switch, Name: name, SwitchType: "Private")
        end

        if data
          switch = {}
          switch[:name] = data["Name"]          
          switch[:type] = data["SwitchType"]
        end

        switch
      end

      def add_vm_adapter(switch)
        data = execute(:add_vm_adapter, VMName: @vmName, SwitchName: switch)

        adapter = {}
        adapter[:id] = data["Id"]
        adapter[:name] = data["Name"]
        adapter[:switch] = data["SwitchName"]
        adapter[:mac_address] = data["MacAddress"]
   
        adapter        
      end

      def remove_vm_adapter(id)
        execute(:remove_vm_adapter, VMName: @vmName, Id: id)        
      end

      def connect_vm_adapter(id, switch)
        execute(:connect_vm_adapter, VMName: @vmName, Id: id, SwitchName: switch)        
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
