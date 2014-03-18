# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "CentOS-6.5"
  config.vm.box_url = "http://cisbic.bioinformatics.ic.ac.uk/files/dhcp/CentOS-6.5.box"
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provision "shell" do |s|
    s.path = "install-xnat.sh"
    s.args = ["/vagrant", "vagrant", "vagrant", "/var/lib/XNAT"]
  end
  config.vm.network "forwarded_port", guest: 8080, host: 8080
end
