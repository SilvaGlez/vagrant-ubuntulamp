# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

settings = YAML.load_file 'settings.yml'

Vagrant.configure("2") do |config|

    # Disables box update checks (for when working offline)
    config.vm.box_check_update = false

    # Sets up the vagrant box name, ip address, hostname and any synced folders
    config.vm.box = "ubuntu/bionic64"
    config.vm.network "private_network", ip: settings['site']['ip']
    config.vm.hostname = settings['site']['sitename']
    config.vm.synced_folder "../", "/var/www/public", :mount_options => ["dmode=777", "fmode=777"]
    config.vm.synced_folder ".", "/var/www", :mount_options => ["dmode=777", "fmode=666"]
    #config.vm.synced_folder "./mysql", "/var/lib/mysql", :mount_options => ["dmode=777", "fmode=666"]
    
    # Optional NFS. Make sure to comment out the synced_folder above
    #config.vm.synced_folder "../", "/var/www/public", :nfs => { :mount_options => ["dmode=777","fmode=777"] }

    ## Sets up the virtualbox memory and name variables
    config.vm.provider "virtualbox" do |vb|
        vb.memory = settings['site']['virtualmemory']
        vb.name = settings['site']['sitename']
    end

    # Runs a shell provisioner script, which is executed the first time the box is created
    # Use vagrant up --provision to rerun the provisioner
    config.vm.provision "shell" do |s|
        s.path = "bootstrap.sh"
        s.args = [ settings['site']['ip'], settings['site']['sitename'], settings['site']['database'], settings['site']['mysqlpassword'] ]
    end

    config.vm.provision "shell", :run => 'always', inline: <<-SHELL
        
        echo -e "\n--- Avvia MySQL ---\n"
        sudo /etc/init.d/mysql start
        
    SHELL


end
