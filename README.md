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
  
  # install OpenSSH Server (Windows Capability) and insert vagrant ssh key on windows guests 
  config.hypervnet.install_ssh_server = true
  
  # install MSYS2 and rsync on windows guests
  config.hypervnet.install_rsync = true
end
```

### Config options

* `install_ssh_server` (Boolean, default: `true`): install OpenSSH Server (Windows Capability) and insert vagrant ssh key on windows guests.
* `install_rsync` (Boolean, default: `true`): install MSYS2 and rsync on windows guests.

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