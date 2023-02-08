terraform {
  required_providers {
    vkcs = {
      source = "vk-cs/vkcs"
      version = "0.1.9"
    }
  }
}

provider "vkcs" {
    username   = var.username
    password   = var.password
    project_id = var.projectid
}

resource "vkcs_compute_instance" "sng_1" {
  name            = "sng_1"
  flavor_id       = data.vkcs_compute_flavor.compute.id
  security_groups = ["default", "ssh+www"]
  image_id = data.vkcs_images_image.compute.id
  availability_zone = "MS1"
  key_pair = data.vkcs_compute_keypair.sng.id

  block_device {
    uuid                  = data.vkcs_images_image.compute.id
    source_type           = "image"
    destination_type      = "volume"
    volume_type           = "ceph-ssd"
    volume_size           = 15
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    uuid = vkcs_networking_network.sng.id
  }

  depends_on = [
    vkcs_networking_network.sng,
    vkcs_networking_subnet.sng
  ]
}


resource "vkcs_networking_floatingip" "sng_1" {
  pool = data.vkcs_networking_network.extnet.name
}

resource "vkcs_compute_floatingip_associate" "sng_1" {
  floating_ip = vkcs_networking_floatingip.sng_1.address
  instance_id = vkcs_compute_instance.sng_1.id
}


resource "vkcs_compute_instance" "sng_2" {
  name            = "sng_2"
  flavor_id       = data.vkcs_compute_flavor.compute.id
  security_groups = ["default", "ssh+www"]
  image_id = data.vkcs_images_image.compute.id
  availability_zone = "MS1"
  key_pair = data.vkcs_compute_keypair.sng.id


  block_device {
    uuid                  = data.vkcs_images_image.compute.id
    source_type           = "image"
    destination_type      = "volume"
    volume_type           = "ceph-ssd"
    volume_size           = 15
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    uuid = vkcs_networking_network.sng.id
  }

  depends_on = [
    vkcs_networking_network.sng,
    vkcs_networking_subnet.sng
  ]
}

resource "vkcs_networking_floatingip" "sng_2" {
  pool = data.vkcs_networking_network.extnet.name
}

resource "vkcs_compute_floatingip_associate" "sng_2" {
  floating_ip = vkcs_networking_floatingip.sng_2.address
  instance_id = vkcs_compute_instance.sng_2.id
}

resource "vkcs_lb_loadbalancer" "sng" {
  name = "sng_loadbalancer"
  vip_subnet_id = "${vkcs_networking_subnet.sng.id}"
  tags = ["sng"]
}

resource "vkcs_networking_floatingip" "sng_lb" {
  pool = data.vkcs_networking_network.extnet.name
}

resource "vkcs_networking_floatingip_associate" "lb_fip" {
  floating_ip = vkcs_networking_floatingip.sng_lb.address
  port_id     = vkcs_lb_loadbalancer.sng.vip_port_id
}

resource "vkcs_lb_listener" "sng" {
  name = "listener"
  protocol = "HTTP"
  protocol_port = 80
  loadbalancer_id = "${vkcs_lb_loadbalancer.sng.id}"
}

resource "vkcs_lb_pool" "sng" {
  name = "pool"
  protocol = "HTTP"
  lb_method = "ROUND_ROBIN"
  listener_id = "${vkcs_lb_listener.sng.id}"
}

resource "vkcs_lb_member" "sng_1" {
  address = "${vkcs_compute_instance.sng_1.network.0.fixed_ip_v4}"
  protocol_port = 80
  pool_id = "${vkcs_lb_pool.sng.id}"
  subnet_id = "${vkcs_networking_subnet.sng.id}"
  weight = 5
}

resource "vkcs_lb_member" "sng_2" {
  address = "${vkcs_compute_instance.sng_2.network.0.fixed_ip_v4}"
  protocol_port = 80
  pool_id = "${vkcs_lb_pool.sng.id}"
  subnet_id = "${vkcs_networking_subnet.sng.id}"
  weight = 5
}