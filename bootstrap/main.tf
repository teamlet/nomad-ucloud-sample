data "template_file" "bootstrap_script" {
  template = file("${path.module}/bootstrap.sh")
  vars = {
    backend_consul_root_password = var.backend_consul_root_password
    terraform_project_url = var.terraform_project_url
    project_dir = var.project_dir
    branch = var.branch
    controller_image = var.controller_image
    k8s_namespace = var.k8s_namespace
    consul_data_volume_size = var.consul_data_volume_size
    consul_instance_type = var.consul_instance_type
    region = var.region
    region_id = var.region_id
    ucloud_pub_key = var.ucloud_pub_key
    ucloud_secret = var.ucloud_secret
    project_id = var.project_id
    controller_cidr = var.controller_cidr
    mgrVpcCidr = var.mgrVpcCidr
    clientVpcCidr = var.clientVpcCidr
    ipv6_api_url = var.ipv6_api_url
    allow_ip = var.allow_ip
    az = join(", ", formatlist("\"%s\"", var.az))
    consul_server_image_id = var.consul_server_image_id
    consul_server_root_password = var.consul_server_root_password
    consul_server_type = var.consul_server_type
    nomad_client_broker_type = var.nomad_client_broker_type
    nomad_client_image_id = var.nomad_client_image_id
    nomad_client_namesvr_type = var.nomad_client_namesvr_type
    nomad_client_root_password = var.nomad_client_root_password
    nomad_server_image_id = var.nomad_server_image_id
    nomad_server_root_password = var.nomad_server_root_password
    nomad_server_type = var.nomad_server_type
    cluster_id = var.cluster_id
    TF_PLUGIN_CONSUL_VERSION = var.TF_PLUGIN_CONSUL_VERSION
    TF_PLUGIN_NULL_VERSION = var.TF_PLUGIN_NULL_VERSION
    TF_PLUGIN_TEMPLATE_VERSION = var.TF_PLUGIN_TEMPLATE_VERSION
    TF_PLUGIN_UCLOUD_VERSION = var.TF_PLUGIN_UCLOUD_VERSION
  }
}

data "template_file" "destroy-script" {
  template = file("${path.module}/destroy.sh")
  vars = {
    project_dir = var.project_dir
  }
}

resource "kubernetes_config_map" "bootstrap-script" {
  metadata {
    name = "bootstrap-script-${var.cluster_id}"
    namespace = var.k8s_namespace
  }
  data = {
    "bootstrap.sh" = data.template_file.bootstrap_script.rendered
    "destroy.sh" = data.template_file.destroy-script.rendered
  }
}

resource kubernetes_persistent_volume_claim code_volume {
  metadata {
    name = "rktmq-bootstrap-code-volume-${var.cluster_id}"
    namespace = var.k8s_namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = var.k8s_storage_class_name

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_pod" "bootstraper" {
  depends_on = [kubernetes_config_map.bootstrap-script]
  metadata {
    name = "bootstraper"
    namespace = var.k8s_namespace
  }
  spec {
    container {
      name = "bootstrap"
      image = var.controller_image
      command = ["sh", "/bootstrap/bootstrap.sh"]
      volume_mount {
        name = "bootstrap-script"
        mount_path = "/bootstrap"
      }
      volume_mount {
        name = "code"
        mount_path = "/project"
      }
      //DO NOT remove security_context or the pod will be recreated on re-apply
      security_context {
        allow_privilege_escalation = false
        privileged = false
        read_only_root_filesystem = false
        run_as_group = 0
        run_as_non_root = false
        run_as_user = 0
      }
    }
    volume {
      name = "bootstrap-script"
      config_map {
        name = kubernetes_config_map.bootstrap-script.metadata[0].name
      }
    }
    volume {
      name = "code"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.code_volume.metadata[0].name
        read_only = false
      }
    }
    //DO NOT remove security_context or the pod will be recreated on re-apply
    security_context {
      fs_group = 2000
      run_as_group = 0
      run_as_non_root = false
      run_as_user = 0
      supplemental_groups = [
        2000,
      ]
    }
  }
}

provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
}

data "ucloud_lbs" "consulLb" {
  depends_on = [kubernetes_pod.bootstraper]
  name_regex = "consulLb-${var.cluster_id}"
}

locals {
  lbId = data.ucloud_lbs.consulLb.lbs[0].id
}

module "consulLbIpv6" {
  source = "../ipv6"
  api_server_url = var.ipv6_api_url
  region_id = var.region_id
  resourceIds = [local.lbId]
}

resource "kubernetes_config_map" "backend-script" {
  metadata {
    name = "backend-script-${var.cluster_id}"
    namespace = var.k8s_namespace
  }
  data = {
    "backend.tfvars" = "address = \"http://[${module.consulLbIpv6.ipv6s[0]}]:8500\""
  }
}

locals {
  controller_pod_label = "rktmq-${var.cluster_id}"
}

resource "kubernetes_deployment" "controller" {
  metadata {
    namespace = var.k8s_namespace
    name = "rkq-controller-${var.cluster_id}"
  }
  spec {
    replicas = 3

    selector {
      match_labels = {
        app = local.controller_pod_label
      }
    }

    template {
      metadata {
        labels = {
          app = local.controller_pod_label
        }
      }
      spec {
        container {
          name = "controller"
          image = var.controller_image
          command = [
            "tail"]
          args = [
            "-f",
            "/dev/null"]
          env {
            name = "TF_VAR_remote_state_backend_url"
            value = "http://[${module.consulLbIpv6.ipv6s[0]}]:8500"
          }
          resources {
            limits {
              cpu = "1"
              memory = "1024Mi"
            }
            requests {
              cpu = "1"
              memory = "1024Mi"
            }
          }
          volume_mount {
            name = "backend-script"
            mount_path = "/backend"
          }
        }
        volume {
          name = "backend-script"
          config_map {
            name = kubernetes_config_map.backend-script.metadata[0].name
          }
        }
      }
    }
  }
}

resource kubernetes_service ctrlService {
  metadata {
    namespace = var.k8s_namespace
    name = "nomad-ctrl-service-${var.cluster_id}"
  }
  spec {
    selector = {
      app = local.controller_pod_label
    }
    port {
      port = 80
      target_port = 80
    }
  }
}