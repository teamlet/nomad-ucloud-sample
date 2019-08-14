variable branch {}
variable backend_consul_root_password {}
variable consul_data_volume_size {}
variable consul_instance_type {}
variable cluster_id {}
variable project_dir {}
variable terraform_project_url {}
variable controller_image {}
variable k8s_namespace {}
variable k8s_storage_class_name {}
variable region {}
variable region_id {}
variable ucloud_pub_key {}
variable ucloud_secret {}
variable project_id {}
variable controller_cidr {}
variable mgrVpcCidr {}
variable clientVpcCidr {}
variable allow_ip {}
variable az {
  type = list(string)
}
variable ipv6_api_url {}
variable consul_server_image_id {}
variable consul_server_root_password {}
variable consul_server_type {}
variable nomad_client_broker_type {}
variable nomad_client_image_id {}
variable nomad_client_namesvr_type {}
variable nomad_client_root_password {}
variable nomad_server_image_id {}
variable nomad_server_root_password {}
variable nomad_server_type {}
variable "TF_PLUGIN_CONSUL_VERSION" {
  default = "2.5.0"
}
variable "TF_PLUGIN_NULL_VERSION" {
  default = "2.1.2"
}
variable "TF_PLUGIN_TEMPLATE_VERSION" {
  default = "2.1.2"
}
variable "TF_PLUGIN_UCLOUD_VERSION" {
  default = "1.11.1"
}