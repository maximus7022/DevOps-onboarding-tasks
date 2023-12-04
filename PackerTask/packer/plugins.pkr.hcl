packer {
  required_plugins {
    amazon = {
      version = " >= 1.0.0 "
      source = "github.com/hashicorp/amazon"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}