terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack" # "terraform.cyverse.org/cyverse/openstack"
    }
  }
}

provider "openstack" {
  tenant_name = var.project
  region = var.region
}

resource "openstack_compute_instance_v2" "os_master_instance" {
  name = "${var.instance_name}-master"
  count = var.instance_count >= 1 ? 1 : 0
  image_id = local.image_uuid
  flavor_name = local.flavor_master
  key_pair = var.keypair
  security_groups = var.security_groups
  power_state = var.power_state
  user_data = var.user_data

  network {
    name = "${var.network}"
  }

  block_device {
    uuid = local.image_uuid
    source_type = var.root_storage_source
    destination_type = var.root_storage_type
    boot_index = 0
    delete_on_termination = var.root_storage_delete_on_termination
    volume_size = local.volume_size
  }

  lifecycle {
    precondition {
      condition = var.image != "" || var.image_name != ""
      error_message = "ERROR: template input image or image_name must be set"
    }
    ignore_changes = [
      image_id, block_device.0.uuid, name, user_data
    ]
  }
}

resource "openstack_compute_instance_v2" "os_worker_instance" {
  name = "${var.instance_name}-worker${count.index}"
  count = var.instance_count >= 2 ? var.instance_count - 1 : 0
  image_id = local.image_uuid
  flavor_name = var.flavor
  key_pair = var.keypair
  security_groups = var.security_groups
  power_state = var.power_state
  user_data = var.user_data

  network {
    name = "${var.network}"
  }

  block_device {
    uuid = local.image_uuid
    source_type = var.root_storage_source
    destination_type = var.root_storage_type
    boot_index = 0
    delete_on_termination = var.root_storage_delete_on_termination
    volume_size = local.volume_size
  }

  lifecycle {
    precondition {
      condition = var.image != "" || var.image_name != ""
      error_message = "ERROR: template input image or image_name must be set"
    }
    ignore_changes = [
      image_id, block_device.0.uuid, name, user_data
    ]
  }
}

data "openstack_networking_network_v2" "ext_network" {
  # make the assumption that there is only 1 external network per region, this will fail if otherwise
  region = var.region
  external = true
}

resource "openstack_networking_floatingip_v2" "os_master_floatingip" {
  count = var.master_floating_ip == "" ? 1 : 0
  pool = data.openstack_networking_network_v2.ext_network.name
  description = "floating ip for ${var.instance_name}-master"
}

resource "openstack_networking_floatingip_v2" "os_worker_floatingips" {
  count = var.instance_count >= 2 ? "${var.instance_count - 1}" : 0
  pool = data.openstack_networking_network_v2.ext_network.name
  description = "floating ip for ${var.instance_name}-worker${count.index} of ${var.instance_count - 1}"
}

# EJS - we need to incorporate a wait before associating floating ips since js2 neutron might need time to "think"
# We should later evaluate if this is just an IU issue or this is an issue across all clouds
# due to constraints of depends_on meta variable, I can only use the first element -- no template syntax, calculations, etc are allowed :(
resource "time_sleep" "master_fip_associate_timewait" {
  depends_on = [openstack_compute_instance_v2.os_master_instance[0]]
  create_duration = var.fip_associate_timewait
}

resource "openstack_compute_floatingip_associate_v2" "os_master_floatingip_associate" {
  floating_ip = var.master_floating_ip == "" ? openstack_networking_floatingip_v2.os_master_floatingip.0.address : var.master_floating_ip
  instance_id = openstack_compute_instance_v2.os_master_instance.0.id
  depends_on = [time_sleep.master_fip_associate_timewait]
}

# EJS - we need to incorporate a wait before associating floating ips since js2 neutron might need time to "think"
# We should later evaluate if this is just an IU issue or this is an issue across all clouds
# due to constraints of depends_on meta variable, I can only use the first element -- no template syntax, calculations, etc are allowed :(
resource "time_sleep" "os_worker_fip_associate_timewait" {
  count = var.instance_count >= 2 ? 1 : 0
  depends_on = [openstack_compute_instance_v2.os_worker_instance[0], openstack_networking_floatingip_v2.os_worker_floatingips[0]]
  create_duration = var.fip_associate_timewait
}

resource "openstack_compute_floatingip_associate_v2" "os_worker_floatingips_associate" {
  count = var.instance_count >= 2 ? "${var.instance_count - 1}" : 0
  floating_ip = openstack_networking_floatingip_v2.os_worker_floatingips[count.index].address
  instance_id = openstack_compute_instance_v2.os_worker_instance[count.index].id
  depends_on = [time_sleep.os_worker_fip_associate_timewait[0]]
}

# resource "openstack_sharedfilesystem_share_v2" "share_01" {
#   count = var.jh_storage_size <= 0 ? 0 : 1
#   name             = "${local.share_name_prefix}-share"
#   description      = "jupyterhub share"
#   share_proto      = "CEPHFS"
#   size             = var.jh_storage_size

#   lifecycle {
#     ignore_changes = [export_locations]
#   }

# }
# resource "openstack_sharedfilesystem_share_access_v2" "share_01_access" {
#   share_id     = "${openstack_sharedfilesystem_share_v2.share_01.0.id}"
#   access_type  = "cephx"
#   access_to    = "${local.share_name_prefix}-share-access"
#   access_level = "rw"
# }

data "openstack_images_image_v2" "instance_image" {
  count = var.image_name == "" ? 0 : 1
  name = var.image_name
  most_recent = true
}

locals {
  flavor_master = var.flavor

  # t
  split_username = split("@", var.username)
  real_username = local.split_username[0]

  #k8s_apply_resource = (
  #  var.k8s_apply_is_http ? var.k8s_apply_resource : base64encode(var.k8s_apply_resource)
  #)
  #k8s_apply_is_base64 = (
  #  var.k8s_apply_is_http ? false : true
  #)
  # k8s_apply_ports = ["${join("\", \"", var.k8s_apply_ports)}"]
  k8s_apply_ports = var.k8s_apply_ports == "" ? [] : try (
    split(",", var.k8s_apply_ports),
    tolist(var.k8s_apply_ports),
    []
  )

  image_uuid = var.image_name == "" ? var.image : data.openstack_images_image_v2.instance_image.0.id
  volume_size = var.root_storage_size > 0 ? var.root_storage_size : null

  # auto calculate gpu time slicing; TODO: move logic to ionosphere?
  # logic
  # if gpu_enable && gpu_timeslice_enable is true, then calculate (below); otherwise, set to 0 (and disable timeslicing)
  #   if var.gpu_timeslice_num > 2, then set to var.gpu_timeslice_num
  #   flavor = g3.xl -> 8 time slices
  #   flavor = g3.large -> 4 time slices
  #   flavor = g3.medium -> 2 time slices
  #   default = 0 time slices (then disable timeslicing)
  gpu_timeslice_num = var.gpu_enable && var.gpu_timeslice_enable ? (var.gpu_timeslice_num >= 2 ? 
    var.gpu_timeslice_num : (var.flavor == "g3.xl" ? 8 : (var.flavor == "g3.large" ? 4 : (var.flavor == "g3.medium" ? 2 : 0)))) : 0
  
  # only enable gpu_timeslice_enable if gpu_timeslice_num > 2
  gpu_timeslice_enable = local.gpu_timeslice_num >= 2 ? true : false
}
