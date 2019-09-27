variable "consul_server_root_password" {
}

variable "nomad_server_root_password" {
}

variable "nomad_client_root_password" {
  type = list(string)
}

variable "ucloud_pub_key" {
}

variable "ucloud_secret" {
}

variable "region" {
  default = "cn-bj2"
}

variable "az" {
  default = [
    "cn-bj2-02",
    "cn-bj2-03",
    "cn-bj2-04",
  ]
}
locals {
  az = length(var.az) == 1 ? [for i in range(3): var.az[0]] : var.az
}
variable "project_id" {
}

variable "consul_server_type" {
  default = "n-highcpu-1"
}

variable "nomad_server_type" {
  default = "n-highcpu-1"
}

variable "nomad_client_namesvr_type" {
  type = list(string)
}

variable "nomad_client_broker_type" {
  type = list(string)
}

variable "allow_ip" {
  default = "0.0.0.0/0"
}

variable "consul_server_image_id" {
}

variable "nomad_server_image_id" {
}

variable "nomad_client_image_id" {
  type = list(string)
}

locals  {
  cluster_id = terraform.workspace
}
variable remote_state_backend_url {}

variable ipv6_server_url {
  default = ""
}
variable region_id {
  default = ""
}
variable env_name {
  default = "test"
}
variable ucloud_api_base_url {}
variable broker_count {
  type = list(number)
}
variable name_server_count {
  type = list(number)
}
variable nomad_server_count {
  type = number
}
variable name_server_local_disk_type {
  type = list(string)
}
variable name_server_udisk_type {
  type = list(string)
}
variable name_server_data_disk_size {
  type = list(number)
}
variable broker_local_disk_type {
  type = list(string)
}
variable broker_udisk_type {
  type = list(string)
}
variable broker_data_disk_size {
  type = list(number)
}
variable name_server_use_udisk {
  type = list(bool)
}
variable broker_use_udisk {
  type = list(bool)
}
locals {
  name_server_local_disk_type = length(var.name_server_local_disk_type) == 1 ? [for i in range(3): var.name_server_local_disk_type[0]] : var.name_server_local_disk_type
  name_server_udisk_type      = length(var.name_server_udisk_type) == 1 ? [for i in range(3):var.name_server_udisk_type[0]] : var.name_server_udisk_type
  name_server_data_disk_size  = length(var.name_server_data_disk_size) == 1 ? [for i in range(3):var.name_server_data_disk_size[0]] : var.name_server_data_disk_size
  broker_local_disk_type      = length(var.broker_local_disk_type) == 1 ? [for i in range(3):var.broker_local_disk_type[0]] : var.broker_local_disk_type
  broker_udisk_type           = length(var.broker_udisk_type) == 1 ? [for i in range(3):var.broker_udisk_type[0]] : var.broker_udisk_type
  broker_data_disk_size       = length(var.broker_data_disk_size) == 1 ? [for i in range(3):var.broker_data_disk_size[0]] : var.broker_data_disk_size
  name_server_use_udisk       = length(var.name_server_use_udisk) == 1 ? [for i in range(3):var.name_server_use_udisk[0]] : var.name_server_use_udisk
  broker_use_udisk            = length(var.broker_use_udisk) == 1 ? [for i in range(3):var.broker_use_udisk[0]] : var.broker_use_udisk
}
variable nomad_server_use_udisk {
  type = bool
}
variable nomad_server_local_disk_type {}
variable nomad_server_udisk_type {}
variable nomad_server_data_disk_size {
  type = number
}
variable consul_server_data_disk_size {
  type = number
}
variable consul_server_local_disk_type {}
variable consul_server_udisk_type {}
variable consul_server_use_udisk {
  type = bool
}
variable namesvr_http_endpoint_port {
  type = number
  default = 8080
}
variable prometheus_port {
  type = number
  default = 9090
}
variable "consul_server_charge_type" {
  default = "dynamic"
}
variable "consul_server_charge_duration" {
  default = 1
}
variable nomad_server_charge_type {
  default = "dynamic"
}
variable "nomad_server_charge_duration" {
  default = 1
}
variable client_charge_type {
  type = list(string)
  default = ["dynamic"]
}
variable client_charge_duration {
  type = list(number)
  default = [1]
}

locals {
  client_charge_type = length(var.client_charge_type) == 1 ? [for i in range(3):var.client_charge_type[0]] : var.client_charge_type
  client_charge_duration = length(var.client_charge_duration) == 1 ? [for i in range(3):var.client_charge_duration[0]] : var.client_charge_duration
}
