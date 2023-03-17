vms = []

windows = {}
windows["box"] = "StefanScherer/windows_2019"
windows["hostname"] = "test-windows"
windows["network"] = []
windowsNet1 = {}
windowsNet1["ip"] = "10.42.201.101"
windowsNet1["netmask"] = "255.255.255.0"
windows["network"].push(windowsNet1)
windowsNet2 = {}
windowsNet2["ip"] = "10.42.202.101"
windowsNet2["netmask"] = "255.255.255.0"
windows["network"].push(windowsNet2)
windowsNet3 = {}
windowsNet3["ip"] = "10.42.203.101"
windowsNet3["netmask"] = "255.255.255.0"
windows["network"].push(windowsNet3)
vms.push(windows)

ubuntu = {}
ubuntu["box"] = "generic/ubuntu2004"
ubuntu["hostname"] = "test-ubuntu"
ubuntu["network"] = []
ubuntuNet1 = {}
ubuntuNet1["ip"] = "10.42.201.102"
ubuntuNet1["netmask"] = "255.255.255.0"
ubuntu["network"].push(ubuntuNet1)
ubuntuNet2 = {}
ubuntuNet2["ip"] = "10.42.202.102"
ubuntuNet2["netmask"] = "255.255.255.0"
ubuntu["network"].push(ubuntuNet2)
ubuntuNet3 = {}
ubuntuNet3["ip"] = "10.42.203.102"
ubuntuNet3["netmask"] = "255.255.255.0"
ubuntu["network"].push(ubuntuNet3)
vms.push(ubuntu)

centos = {}
centos["box"] = "generic/centos7"
centos["hostname"] = "test-centos"
centos["network"] = []
centosNet1 = {}
centosNet1["ip"] = "10.42.201.103"
centosNet1["netmask"] = "255.255.255.0"
centos["network"].push(centosNet1)
centosNet2 = {}
centosNet2["ip"] = "10.42.202.103"
centosNet2["netmask"] = "255.255.255.0"
centos["network"].push(centosNet2)
centosNet3 = {}
centosNet3["ip"] = "10.42.203.103"
centosNet3["netmask"] = "255.255.255.0"
centos["network"].push(centosNet3)
vms.push(centos)

Vagrant.configure("2") do |config|
  vms.each do |node|
    config.vm.define node["hostname"] do |node_config|    
      node_config.vm.box = node["box"]
      node_config.vm.hostname = node["hostname"]   
      node["network"].each do |network|
        node_config.vm.network :private_network, ip: network["ip"], netmask: network["netmask"]
      end
      node_config.vm.synced_folder ".", "/vagrant", disabled: false, type: "rsync", rsync__exclude: ".git/"

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