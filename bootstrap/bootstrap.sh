cd /project
if [ ! -d "${project_dir}" ]; then
  git clone ${terraform_project_url}
fi
cd ${project_dir}
git checkout ${branch}
cd control-network
if [ ! -f "terraform.tfvars" ]; then
  cat>terraform.tfvars<<-EOF
  ucloud_pub_key = "${ucloud_pub_key}"
  ucloud_secret = "${ucloud_secret}"
  region = "${region}"
  region_id = "${region_id}"
  az = [${az}]
  project_id = "${project_id}"
  cidr = "${controller_cidr}"
  vpcName = "controllerVpc"
  subnetName = "controllerSubnet"
  consul_image_id = "${consul_server_image_id}"
  controller_image_id = ""
  controler_instance_type = ""
  allow_ip = "${allow_ip}"
  root_password = ""
  tag = "${cluster_id}"
  terraform_project_url = ""
  git_branch = ""
  project_root_dir = ""
  project_dir = ""
  consul_root_password = "${backend_consul_root_password}"
  consul_data_volume_size = ${consul_data_volume_size}
  consul_instance_type = "${consul_instance_type}"
  ipv6_api_url = "${ipv6_api_url}"
  controller_count = 0
  provision_from_kun = true
  EOF
fi
if [ ! -f "inited" ]; then
  terraform init -plugin-dir=/plugin
  terraform apply --auto-approve -input=false
  touch inited
fi
#give consul some time to be stablized
sleep 10
if [ ! -d "/backend" ]; then
  mkdir /backend
fi
if [[ ! -z "${TF_VAR_remote_state_backend_url}"]]; then
  export TF_VAR_remote_state_backend_url=http://[$(terraform output -json | jq -r '.backend_ip.value')]:8500
  echo export TF_VAR_remote_state_backend_url=$TF_VAR_remote_state_backend_url >> ~/.bashrc
  echo address=\"$TF_VAR_remote_state_backend_url\" > /backend/backend.tfvars
  echo remote_state_backend_url=\"$TF_VAR_remote_state_backend_url\" >> /backend/backend.tfvars
fi

if [ ! -f "../network/terraform.tfvars.json" ]; then
  cat>../network/terraform.tfvars.json<<-EOF
  {
    "region": "${region}",
    "ucloud_pub_key": "${ucloud_pub_key}",
    "ucloud_secret": "${ucloud_secret}",
    "project_id": "${project_id}",
    "mgrVpcCidr": "${mgrVpcCidr}",
    "clientVpcCidr": "${clientVpcCidr}"
  }
  EOF
fi
if [ ! -f "../terraform.tfvars.json" ]; then
  cat>../terraform.tfvars.json<<-EOF
  {
      "allow_ip": "${allow_ip}",
      "az": [${az}],
      "clientSubnetCidr": "${clientVpcCidr}",
      "consul_server_image_id": "${consul_server_image_id}",
      "consul_server_root_password": "${consul_server_root_password}",
      "consul_server_type": "${consul_server_type}",
      "mgrSubnetCidr": "${mgrVpcCidr}",
      "nomad_client_broker_type": "${nomad_client_broker_type}",
      "nomad_client_image_id": "${nomad_client_image_id}",
      "nomad_client_namesvr_type": "${nomad_client_namesvr_type}",
      "nomad_client_root_password": "${nomad_client_root_password}",
      "nomad_server_image_id": "${nomad_server_image_id}",
      "nomad_server_root_password": "${nomad_server_root_password}",
      "nomad_server_type": "${nomad_server_type}",
      "project_id": "${project_id}",
      "region": "${region}",
      "ucloud_pub_key": "${ucloud_pub_key}",
      "ucloud_secret": "${ucloud_secret}",
      "TF_PLUGIN_CONSUL_VERSION": "${TF_PLUGIN_CONSUL_VERSION}",
      "TF_PLUGIN_NULL_VERSION": "${TF_PLUGIN_NULL_VERSION}",
      "TF_PLUGIN_TEMPLATE_VERSION": "${TF_PLUGIN_TEMPLATE_VERSION}",
      "TF_PLUGIN_UCLOUD_VERSION": "${TF_PLUGIN_UCLOUD_VERSION}",
      "ipv6_server_url": "${ipv6_api_url}",
      "region_id": "${region_id}",
      "provision_from_kun": true
  }
  EOF
fi
cd ../network
rm -f destroyed
if [ ! -f "inited" ]; then
  terraform init -plugin-dir=/plugin -backend-config=/backend/backend.tfvars
  terraform workspace new ${cluster_id}
  terraform workspace select ${cluster_id}
  terraform apply --auto-approve -input=false
  touch inited
fi
cd ..
rm -f destroyed
if [ ! -f "inited" ]; then
  terraform init -plugin-dir=/plugin -backend-config=/backend/backend.tfvars
  terraform workspace new ${cluster_id}
  terraform apply --auto-approve -input=false -var-file=terraform.tfvars.json
  touch inited
fi
tail -f /dev/null