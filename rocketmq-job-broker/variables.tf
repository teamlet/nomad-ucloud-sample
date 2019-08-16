locals {
  namesvc-name = "namesvc-service-${var.namesvr_clusterId}"
  broker_clusterId = terraform.workspace
  brokersvc-name = "brokersvc-service-${local.broker_clusterId}"
  broker-job-hcl  = "${path.module}/broker-job.hcl"
  console-job-hcl = "${path.module}/console-job.hcl"
  az = data.terraform_remote_state.nomad.outputs.az
  region = data.terraform_remote_state.nomad.outputs.region
}
variable rocketmq_docker_image {}
variable rocketmq_version {}
variable allow_multiple_tasks_in_az {}
variable namesvr_clusterId {}
variable nomad_cluster_id {}
variable remote_state_backend_url {
  default = "http://localhost:8500"
}
variable provision_from_kun {}