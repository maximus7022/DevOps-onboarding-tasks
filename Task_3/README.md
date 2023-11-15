# Deploying WordPress on a Virtual Machine with Terraform and Ansible

This documentation outlines the process of using Terraform in conjunction with Ansible to provision a Virtual Machine (VM) and install WordPress on it. The solution involves utilizing Terraform and Vagrant to create the VM and Ansible to perform the WordPress installation.

## Use of Vagrant

Vagrant was used as the provider to create the virtual machine. 

It allows flexible customization of the required machine configuration and the use of ready-made assemblies in the form of vagrant.box, which are available on the Internet (smth. like public docker images).

### `Vagrantfile`

The `Vagrantfile` contains configuration details for the Vagrant VM, including network settings and provisioning using Ansible:

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.provider "virtualbox" do |vb|
    vb.name = "wordpress"
    vb.cpus = 2
    vb.memory = "1024"
  end
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "./ansible/playbook.yml"
  end
end
```

- Configures a CentOS 7 VM using the `centos/7` Vagrant box.
- Maps port 80 on the guest (VM) to port 8080 on the host.
- Sets the VM's name, CPU, and memory specifications.
- Utilizes Ansible as a provisioner by specifying the playbook for configuration (`./ansible/playbook.yml`).

In process of creation of the VM, with help of specified provisioner Vagrant automatically provides needed target host configuration to Ansible, so we don't need to hardcode it.
## Ansible Playbook and Related Files

The Ansible playbook and associated files handle the installation and setup of WordPress on the deployed VM.

### `playbook.yml`

The `playbook.yml` file uses dedicated role with all tasks to deploy Wordpress:

```yml
---
- hosts: all
  become: yes
  roles:
    - roles/ansiblewordpress
```
- **`hosts: all`** - is the only acceptable value while using Vagrant.

- **`become: yes`** - gives ansible root access to the VM.
---
**`ansiblewordpress`** role contains some files with task definitions for different components of the Wordpress installation.

**`templates`** folder:
- [`wp-config.php.j2`](./ansible/roles/templates/wp-config.php.j2) - contains predefined wordpress configuration template.

**`tasks`** folder:
- [`main.yml`](./ansible/roles/tasks/main.yml) - responsible for installation of basic dependencies (epel-release, php, etc.) and executing tasks, contained in other files.
- [`database.yml`](./ansible/roles/tasks/database.yml) - installs and configures database engine for Wordpress to use.
- [`webserver.yml`](./ansible/roles/tasks/webserver.yml) - installs apache server and running it.
- [`wordpress.yml`](./ansible/roles/tasks/wordpress.yml) - initiates wordpress download and applying predefined configuration stored in `wp-config.php.j2` template.

**`vars`** folder:
- [`main.yml`](./ansible/roles/vars/main.yml) - consists of a set of local wordpress database credentials (**must be changed for the security reasons**).
## Terraform Configuration Files

### `providers.tf`

The `providers.tf` file specifies the required provider for Terraform, in this case, leveraging the Vagrant provider:

```hcl
terraform {
  required_providers {
    vagrant = {
      source  = "bmatcuk/vagrant"
      version = "~> 4.0.0"
    }
  }
}
```

- **`vagrant` provider:** Defines the Vagrant provider and specifies the source and version for the provider.

### `main.tf`

The `main.tf` file contains Terraform resource for creating a Vagrant VM:

```hcl
resource "vagrant_vm" "wordpress" {
  env = {
    VAGRANTFILE_HASH = md5(file("./Vagrantfile")),
  }
  get_ports = true
}
```

- **`vagrant_vm` resource:** Defines a Vagrant VM resource named "wordpress". It uses the Vagrantfile and retrieves the ports information for the VM.

## Usage

To deploy WordPress on a VM using Terraform and Ansible, follow these steps:

1. **Ensure Dependencies:**

   - Install Terraform.
   - Have Vagrant and VirtualBox (or another supported provider) installed.

2. **Prepare Environment:**

   Clone this project to your local machine.
3. **Initialize Terraform:**

   Run `terraform init` to initialize Terraform and download the necessary plugins.

4. **Deploy VM:**

   Execute `terraform apply` and approve the changes to create the VM.

After this, your VM with Wordpress under the hood will be ready to use, just visit IP address and port configured in the `Vagrantfile` (http://localhost:8080 by default).