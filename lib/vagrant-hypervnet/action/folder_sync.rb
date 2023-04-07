require "log4r"

module VagrantPlugins
  module HyperVNet    
    module Action
      class FolderSync

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::hypervnet::folder_sync")
        end

        def call(env)
          # Continue the middleware chain.
          @app.call(env)

          machine = env[:machine]
          if(machine.config.hypervnet.folder_sync_on_provision)
            env[:ui].output(I18n.t("vagrant_hypervnet.folder_sync"))
            callable = Vagrant::Action::Builder.new
            callable.use Vagrant::Action::Builtin::SyncedFolders
            machine.action_raw(:sync_folders, callable, env)
          end
        end
      end
    end
  end
end