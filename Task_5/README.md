
  # Deploying Nagios Core to Vagrant VM with Ansible
  ## Description
  This documentation outlines the process of **`Nagios Core`** deployment to **`Vagrant VM`**, as well as configuration of its monitoring targets using **`Ansible`**. 
  
  ## Requirements
  - **`Ansible`** + **`Vagrant`** installed.

## Vagrantfile overview
To provision the VM for further deployment, we need to define our VM configuration in **`Vagrantfile`**:
```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"                                  # centos 7 as a base image
  config.vm.network "forwarded_port", guest: 80, host: 8082   # port forwarding (http://localhost:8082)
  
  config.vm.provider "virtualbox" do |vb|                     # VM properties
    vb.name = "nagios"
    vb.cpus = 2
    vb.memory = "1024"
  end

  config.vm.provision "ansible" do |ansible|                  # ansible playbook as a provisioner to begin 
    ansible.playbook = "./ansible/playbook.yml"               # Nagios installation right after VM creation
  end
end
```

## Ansible playbook
To automate the process of Nagios installation, such playbook was developed:
```yml
---
- hosts: all
  become: yes
  roles:
    - roles/apache              # role, that installs apache httpd server
    - roles/nagios              # role, that installs nagios core
    - roles/nagios-host-conf    # role, that configures hosts to monitor
```
Each playbook role contains detailed and commented instructions to execute on the remote host for a successful Nagios Core installation and configuration.

## Details about **`nagios-host-conf`** role
This role is responsible for Nagios server configuration, defining new target hosts and configuring monitoring preferences for them.

It has such structure:
- **`tasks`**
  - `main.yml`      <-- main role tasks
- **`templates`**
  - `docker.j2`     <-- docker host config file
  - `wordpress.j2`  <-- wordpress host config file
- **`vars`**
  - `main.yml`    <-- contains target host ip address

## How to run?
To create the VM and begin ansible playbook execution simply run in the project root folder:

    # vagrant up
---