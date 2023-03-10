vms = []

windows = {}
windows["box"] = "StefanScherer/windows_2019"
windows["hostname"] = "test-windows"
windows["network"] = []
windowsNet1 = {}
windowsNet1["ip"] = "10.42.201.101"
windowsNet1["netmask"] = "24"
windows["network"].push(windowsNet1)
windowsNet2 = {}
windowsNet2["ip"] = "10.42.202.101"
windowsNet2["netmask"] = "24"
windows["network"].push(windowsNet2)
windowsNet3 = {}
windowsNet3["ip"] = "10.42.203.101"
windowsNet3["netmask"] = "24"
windows["network"].push(windowsNet3)
vms.push(windows)

ubuntu = {}
ubuntu["box"] = "generic/ubuntu2004"
ubuntu["hostname"] = "test-ubuntu"
ubuntu["network"] = []
ubuntuNet1 = {}
ubuntuNet1["ip"] = "10.42.201.102"
ubuntuNet1["netmask"] = "24"
ubuntu["network"].push(ubuntuNet1)
ubuntuNet2 = {}
ubuntuNet2["ip"] = "10.42.202.102"
ubuntuNet2["netmask"] = "24"
ubuntu["network"].push(ubuntuNet2)
ubuntuNet3 = {}
ubuntuNet3["ip"] = "10.42.203.102"
ubuntuNet3["netmask"] = "24"
ubuntu["network"].push(ubuntuNet3)
vms.push(ubuntu)

centos = {}
centos["box"] = "generic/centos7"
centos["hostname"] = "test-centos"
centos["network"] = []
centosNet1 = {}
centosNet1["ip"] = "10.42.201.103"
centosNet1["netmask"] = "24"
centos["network"].push(centosNet1)
centosNet2 = {}
centosNet2["ip"] = "10.42.202.103"
centosNet2["netmask"] = "24"
centos["network"].push(centosNet2)
centosNet3 = {}
centosNet3["ip"] = "10.42.203.103"
centosNet3["netmask"] = "24"
centos["network"].push(centosNet3)
vms.push(centos)

Vagrant.configure("2") do |config|

  config.trigger.before :"VagrantPlugins::HyperV::Action::StartInstance", type: :action do |trigger|
    trigger.info = "Adding network adapter..."
    trigger.ruby do |env,machine|
      machine.config.vm.networks.select{|network| network[0] == :private_network}.map{|network| network[1]}.each{|network|

        ipAddr = IPAddr.new network[:ip]
        subnet = ipAddr.mask network[:netmask]
        host = subnet.succ
        name = defined?(network[:name]) ? network[:name] : subnet.to_s

        Vagrant::Util::PowerShell.execute('bin/add-hyperv-network-adapter.ps1', [
          '-name', name,
          '-subnet', subnet.to_s,
          '-prefixLength', network[:netmask],
          '-hostAddress', host.to_s, 
          '-nat', '$False',
          '-vmName', machine.provider_config.vmname
        ])
      }      
    end
  end

  config.trigger.after :"Vagrant::Action::Builtin::WaitForCommunicator", type: :action do |trigger|
    trigger.info = "Configuring network adapter..."
    trigger.ruby do |env,machine|

      if machine.provider_name == :hyperv

        cmd = "Get-VMNetworkAdapter -VMName '" + machine.provider_config.vmname +
           "' | Select-Object -Property SwitchName,MacAddress | ConvertTo-Json"
        adapters = JSON.parse(Vagrant::Util::PowerShell.execute_cmd(cmd)).reduce({}) {
          |map, item| map.update(item["SwitchName"] => item["MacAddress"])}
        puts adapters.inspect

        machine.config.vm.networks.select{|network| network[0] == :private_network}.map{|network| network[1]}.each{|network|

          ipAddr = IPAddr.new network[:ip]
          subnet = ipAddr.mask network[:netmask]
          host = subnet.succ
          name = defined?(network[:name]) ? network[:name] : subnet.to_s

          config = VagrantPlugins::Shell::Config.new
          if machine.guest.name == :windows
            config.path = "./bin/configure-static-ip.ps1"
            config.args = [
              '-adapterMAC', adapters[name],
              '-address', ipAddr.to_s,
              '-prefixLength', network[:netmask]
            ]  
          else
            config.path = "./bin/configure-static-ip.sh"
            config.args = [
              '-m', adapterMac,
              '-i', ipAddr.to_s,
              '-n', network[:netmask]
            ]  
          end
          config.finalize!
          provisioner = VagrantPlugins::Shell::Provisioner.new(machine, config)
          provisioner.provision
        }      
      end
    end
  end

  config.trigger.before :"Vagrant::Action::Builtin::SyncedFolders", type: :action do |trigger|
    trigger.info = "Configuring rsync..."
    trigger.ruby do |env,machine|

      if machine.provider_name == :hyperv && machine.guest.name == :windows
        sentinel = machine.data_dir.join("configure_rsync")

        if !sentinel.file?
          config = VagrantPlugins::Shell::Config.new
          config.path = 'bin/install-rsync.ps1'
          config.finalize!
          provisioner = VagrantPlugins::Shell::Provisioner.new(machine, config)
          provisioner.provision

          sentinel.open("w") do |f|
            f.write(Time.now.to_i.to_s)
          end
        end
      end
    end
  end

  vms.each do |node|
    config.vm.define node["hostname"] do |node_config|    
      node_config.vm.box = node["box"]
      node_config.vm.hostname = node["hostname"]   
      node_config.vm.network :public_network, bridge: "Default Switch"
      node_config.vm.network :private_network, ip: node["ip"], netmask: "24", name: "10.42.200.0"
      node_config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: ".git/"

      #node_config.vm.communicator = 'winrm'
        
      node_config.vm.provider "hyperv" do |p|
        p.linked_clone = true
        p.vmname = node["hostname"]
        p.cpus = 2
        p.maxmemory = 4096
        p.vm_integration_services = {
          guest_service_interface: true,
          time_synchronization: true,
          shutdown: true,
          heartbeat: true,
          vss: true
        }
      end
    end
  end
end