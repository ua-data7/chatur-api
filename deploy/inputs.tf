variable "username" {
  type = string
  description = "username"
}

variable "project" {
  type = string
  description = "project name"
}

variable "region" {
  type = string
  description = "string, openstack region name; default = IU"
  default = "IU"
}

variable "network" {
  type = string
  description = "network to use for vms"
  default = "auto_allocated_network"
}

variable "instance_name" {
  type = string
  description = "name of jupyterhub instance"
}

variable "instance_count" {
  type = number
  description = "number of instances to launch"
  default = 1 
}

variable "image" {
  type = string
  description = "string, image id; image will have priority if both image and image name are provided"
  default = ""
}

variable "image_name" {
  type = string
  description = "string, name of image; image will have priority if both image and image name are provided"
  default = ""
}

variable "flavor" {
  type = string
  description = "flavor or size for the worker instances to launch"
  default = "m1.tiny"
}

# variable "flavor_master" {
#   type = string
#   description = "flavor or size for the master instance to launch"
#   default = "m3.medium"
# }

variable "keypair" {
  type = string
  description = "keypair to use when launching"
  default = ""
}

variable "power_state" {
  type = string
  description = "power state of instance"
  default = "active"
}

variable "ip_pool" {
  type = string
  description = "deprecated"
  default = "public"
}

variable "user_data" {
  type = string
  description = "cloud init script"
  default = ""
}

variable "security_groups" {
  type = list(string)
  description = "array of security group names, either as a a comma-separated string or a list(string). The default is ['default', 'cacao-default']. See local.security_groups"
  default = ["default", "cacao-default"]
}

variable "master_floating_ip" {
  type = string
  description = "floating ip to assign, if one was pre-created; otherwise terraform will auto create one"
  default = ""
}

variable "master_hostname" {
  type = string
  description = "public facing hostname, if set, will be used for the callback url; default is not use set one, which will then use the floating ip"
  default = ""
}

variable "gpu_enable" {
  type = bool
  description = "boolean, whether to enable gpu components"
  default = false
}

variable "gpu_timeslice_enable" {
  type = bool
  description = "boolean, whether to enable gpu timeslicing (only used if gpu_enable == true)"
  default = false
}

variable "gpu_timeslice_num" {
  type = number
  description = "number, number of time slices if gpu timeslicing is enabled; 0 is default, which means auto-slice (js2 only)"
  default = 0
}

variable "do_ansible_execution" {
  type = bool
  description = "boolean, whether to execute ansible"
  default = true
}

variable "ansible_execution_dir" {
  type = string
  description = "string, directory to execute ansible, including location to create the inventory file, where the requirements file is, etc"
  default = "./ansible"
}

variable "k3s_traefik_disable" {
  type = bool
  description = "bool, if true will disable traefik"
  default = true
}

variable "run_k8s_apply" {
  type = bool
  description = "bool, if true will run k8s apply"
  default = false
}

variable "k8s_apply_is_http" {
  type = bool
  description = "bool, if true k8s apply will use a http link to a yaml otherwise will use a string of a full file"
  default = true
}

variable "k8s_apply_resource_base64" {
  type = string
  description = "a base64-encoded string of either a link or a full yaml file(required if run_k8s_apply is true)"
  default = ""
}

variable "k8s_apply_ports" {
  type = any
  description = "a list of port-service-name:port_numbers for the ingress made by k8s apply, either as a comma-separated string or a list(string)"
  default = []
}

variable "fip_associate_timewait" {
  type = string
  description = "number, time to wait before associating a floating ip in seconds; needed for jetstream; will not be exposed to downstream clients"
  default = "30s"
}

variable "root_storage_source" {
  type = string
  description = "string, source currently supported is image; future values will include volume, snapshot, blank"
  default = "image"
}

variable "root_storage_type" {
  type = string
  description = "string, type is either local or volume"
  default = "local"
}

variable "root_storage_size" {
  type = number
  description = "number, size in GB"
  default = -1
}

variable "root_storage_delete_on_termination" {
  type = bool
  description = "bool, if true delete on termination"
  default = true
}

variable "chatur_oauth2_client_id" {
  type = string
  description = "string, oauth2 client id"
}

variable "chatur_oauth2_client_secret" {
  type = string
  description = "string, oauth2 client secret"
}

variable "chatur_oauth2_discovery" {
  type = string
  description = "string, oauth2 discovery"
}

variable "chatur_oauth2_realm" {
  type = string
  description = "string, oauth2 realm"
}

variable "chatur_oauth2_secret" {
  type = string
  description = "string, oauth2 secret"
}

variable "chatur_api_key" {
  type = string
  description = "string, api key"
}

variable "chatur_address" {
  type = string
  description = "string, dns address for ingress"
}
