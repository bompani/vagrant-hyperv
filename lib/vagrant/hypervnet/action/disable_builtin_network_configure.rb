require "log4r"

module VagrantPlugins
  module HyperVNet    
    module Action
      class DisableBuiltinNetworkConfigure

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::hypervnet::network")
        end

        def call(env)
          @logger.info("Disabling built-in Hyper-V provider network configure...")          
          sentinel = env[:machine].data_dir.join("action_configure")
          
          # Create the sentinel
          if !sentinel.file?
          sentinel.open("w") do |f|
              f.write(Time.now.to_i.to_s)
          end

          # Continue the middleware chain.
          @app.call(env)
      end
    end
  end
end