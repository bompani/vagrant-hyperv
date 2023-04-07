# vagrant-hypervnet

*vagrant-hypervnet* is a [Vagrant](http://vagrantup.com) plugin which extends Hyper-V provider implementing networks creation and
configuration.

[![Gem Version](https://badge.fury.io/rb/vagrant-hypervnet.svg)](https://badge.fury.io/rb/vagrant-hypervnet)
[![Downloads](http://ruby-gem-downloads-badge.herokuapp.com/vagrant-hypervnet?type=total&style=flat)](https://rubygems.org/gems/vagrant-hypervnet)

## Features

* Create Hyper-V switches. 
* Add an host IP address for each private network
* Add a and configure a guest network adapter for each configured public or private network 
* Optionally install and configure SSH server in windows guests.
* Optionally install and configure rsync ([MSYS2](https://www.msys2.org/)) in windows guests.

## Installation

```
$ vagrant plugin install vagrant-hypervnet
```

## Configuration

```ruby
Vagrant.configure("2") do |config|
  
  # installs OpenSSH Server (Windows Capability) and inserts vagrant ssh key on windows guests 
  config.hypervnet.install_ssh_server = true
  
  # installs MSYS2 and rsync on windows guests
  config.hypervnet.install_rsync = true

  # enablee synced_folder synchronization before provision
  config.hypervnet.folder_sync_on_provision = true

  # Hyper-V switch connected to vagrant management interface
  config.hypervnet.default_switch = "Default Switch"

  # Hyper-V internal network: a new switch is created if can't find an existent switch with the specified subnet (192.168.100.100/24)
  config.vm.network :private_network, ip: "192.168.100.101", netmask: "255.255.255.0"

# Hyper-V internal network: a new switch is created if can't find an existent switch whith the specified name ("my-internal-network") 
  config.vm.network :private_network, ip: "192.168.102.101", netmask: "255.255.255.0" hyperv__bridge: "my-internal-network"  

  # Hyper-V private network: a new switch is created if can't find an existent switch whith the specified name ("my-private-network") 
  config.vm.network :private_network, ip: "192.168.101.101", netmask: "255.255.255.0" hyperv__private: "my-private-network"

  # Hyper-V external network: the existent switch whith the specified name ("my-external-network") is connected to this vm adapter
  config.vm.network :public_network, ip: "192.168.102.101", netmask: "255.255.255.0" hyperv__bridge: "my-external-network"

  # rsync synched folder
  config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: ".git"
end
```

### Config options

* `install_ssh_server` (Boolean, default: `true`): installs OpenSSH Server (Windows Capability) and inserts vagrant ssh key on windows guests.
* `install_rsync` (Boolean, default: `true`): installs MSYS2 and rsync on windows guests if an rsync synced folder is defined .
* `folder_sync_on_provision` (Boolean, default: `true`): if enabled invokes synced folders synchronization before provision.
* `default_switch` (String, default: `Default Switch`): Hyper-V switch connected to interface used by vagrant to communicate with the vm.

## Usage

```
$ vagrant init
$ vagrant up --provider=hyperv
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request