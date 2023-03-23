require "log4r"

module VagrantPlugins
  module HyperVNet    
    module Action
      class DisableBuiltinNetworkConfigure

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::hypervnet::disable_builtin_network_configure")
        end

        def call(env)
          @logger.info("Disabling built-in Hyper-V provider network configure...")       
          
          
          env[:machine].config.vm.networks.each do |type, options|
            if options.key?(:bridge)
              bridge = options.delete(:bridge)
              options[:hyperv__bridge] = bridge
            end
          end

          sentinel = env[:machine].data_dir.join("action_configure")
          
          # Create the sentinel
          if !sentinel.file?
            sentinel.open("w") do |f|
                f.write(Time.now.to_i.to_s)
            end
          end

          # Continue the middleware chain.
          @app.call(env)
        end
      end
    end
  end
end