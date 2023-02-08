data "vkcs_compute_flavor" "compute" {
  name = "Basic-1-1-10"
}

data "vkcs_networking_network" "extnet" {
  name = "ext-net"
}

data "vkcs_images_image" "compute" {
  name = "Ubuntu-22.04-202208"
}

data "vkcs_compute_keypair" "sng" {
  name = "ilyanyrkov"
}

resource "vkcs_networking_network" "sng" {
  name = "sng_net"
}

resource "vkcs_networking_subnet" "sng" {
  name       = "sng_subnet"
  network_id = vkcs_networking_network.sng.id
  cidr       = "10.0.1.0/24"
  ip_version = 4
}

resource "vkcs_networking_router" "sng" {
  name                = "sng-router"
  admin_state_up      = true
  external_network_id = data.vkcs_networking_network.extnet.id
}

resource "vkcs_networking_router_interface" "sng" {
  router_id = vkcs_networking_router.sng.id
  subnet_id = vkcs_networking_subnet.sng.id
}
