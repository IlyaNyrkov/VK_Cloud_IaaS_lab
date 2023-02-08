variable "image_tag" {
  type = string
  default = "1.1.1"
}

source "openstack" "nginx" {
  source_image_filter {
    filters {
      name = "Ubuntu-22.04-202208"
    }
  }

  flavor                  = "Basic-1-1-10"
  ssh_username            = "ubuntu"
  security_groups         = ["default", "ssh+www"]
  volume_size             = 20
  volume_availability_zone = "MS1"
  config_drive            = "true"
  use_blockstorage_volume = "true"
  networks                = ["298117ae-3fa4-4109-9e08-8be5602be5a2"]
  

  image_name = "nginx-${var.image_tag}"
}

build {
  sources = ["source.openstack.nginx"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt install nginx -y"
    ]
  }
}