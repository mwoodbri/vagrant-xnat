# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
  end
  config.vm.provision "shell" do |s|
    s.path = "install-xnat.sh"
<<<<<<< HEAD
    s.args = ["/vagrant", "vagrant", "/var/lib/XNAT", "false"]
=======
    s.args = ["/vagrant", "/var/lib/XNAT", "false"]
>>>>>>> Ubuntu 14.04
  end
  config.vm.network "forwarded_port", guest: 8080, host: 8080
end
