# frozen_string_literal: true

require_relative "lib/vagrant-hypervnet/version"

Gem::Specification.new do |spec|
  spec.name = "vagrant-hypervnet"
  spec.version = VagrantPlugins::HyperVNet::VERSION
  spec.authors = ["Luca Bompani"]
  spec.email = ["luca.bompani@unibo.it"]

  spec.summary = "Vagrant plugin to configure Hyper-V network."
  spec.description = "Vagrant plugin which extends Hyper-V provider implementing networks creation and configuration."
  spec.homepage = "https://github.com/bompani/vagrant-hyperv"
  spec.required_ruby_version = ">= 2.6.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
