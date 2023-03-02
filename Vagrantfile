# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  hostname = 'test'

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
        machine.config.vm.networks.select{|network| network[0] == :private_network}.map{|network| network[1]}.each{|network|

        ipAddr = IPAddr.new network[:ip]
        subnet = ipAddr.mask network[:netmask]
        host = subnet.succ
        name = defined?(network[:name]) ? network[:name] : subnet.to_s

        cmd = "(Get-VMNetworkAdapter -VMName '" + machine.provider_config.vmname + "' -Name '" + name + "').MacAddress"
        adapterMac = Vagrant::Util::PowerShell.execute_cmd(cmd)    

        config = VagrantPlugins::Shell::Config.new
        config.path = "./bin/configure-static-ip.ps1"
        config.args = [
          '-adapterMAC', adapterMac,
          '-address', ipAddr.to_s,
          '-prefixLength', network[:netmask]
        ]
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

      if machine.provider_name == :hyperv
        config = VagrantPlugins::Shell::Config.new
        config.path = 'bin/install-rsync.ps1'
        config.finalize!
        provisioner = VagrantPlugins::Shell::Provisioner.new(machine, config)
        provisioner.provision
      end
    end
  end

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "StefanScherer/windows_2019"
  
  config.vm.hostname = hostname
  
  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  config.vm.network :public_network, bridge: "Default Switch"
  config.vm.network :private_network, ip: "10.42.200.100", netmask: "24", name: "10.42.200.0"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: ".git/"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL

  config.vm.communicator = 'winrm'
  
  config.vm.provider "hyperv" do |p|
    p.linked_clone = true
    p.vmname = hostname
    p.cpus = 2
    p.memory = 4096
    p.vm_integration_services = {
      guest_service_interface: true,
      time_synchronization: true,
      shutdown: true,
      heartbeat: true,
      vss: true
    }
  end
end
