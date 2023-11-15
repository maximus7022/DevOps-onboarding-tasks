resource "vagrant_vm" "wordpress" {
  env = {
    VAGRANTFILE_HASH = md5(file("./Vagrantfile")),
  }
  get_ports = true
}
