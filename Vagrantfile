# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "hashicorp/precise64"
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provision "shell" do |s|
    s.path = "install-xnat.sh"
    s.args = ["/vagrant", "vagrant", "vagrant", "/var/lib/XNAT", "false"]
  end
  config.vm.network "forwarded_port", guest: 8080, host: 8080
end
