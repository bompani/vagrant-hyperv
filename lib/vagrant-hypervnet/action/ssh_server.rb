require "log4r"

module VagrantPlugins
  module HyperVNet    
    module Action
      class SshServer

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::hypervnet::ssh_server")
        end

        def call(env)
          machine = env[:machine]
          if(machine.config.hypervnet.install_ssh_server)
            if machine.guest.capability?(:sshd_installed) && !machine.guest.capability(:sshd_installed)
                @logger.info("Installing OpenSSH server...")          
                machine.guest.capability(:sshd_install)
            end
          end

          # Continue the middleware chain.
          @app.call(env)
        end
      end
    end
  end
end