job "${job-name}" {
  datacenters = ["${region}"]
  region = "${region}"
  constraint {
    attribute = "$${node.class}"
    value = "${node-class}"
  }
  constraint {
    attribute = "$${meta.az}"
    operator = "distinct_property"
    value = "${task-limit-per-az}"
  }
  group "namesvr" {
    count = ${count}
    spread {
      attribute = "$${meta.az}"
    }
    update {
      max_parallel = 1
      health_check = "checks"
      min_healthy_time = "1m"
      healthy_deadline = "5m"
      progress_deadline = "10m"
    }
    task "namesvr" {
      driver = "docker"
      config {
        image = "${namesvr-image}"
        port_map = {
          tcp = 9876
        }
        command = "${cmd}"
        args = []
      }
      resources {
        cpu = 1000
        memory = 2048
        network {
          port "tcp" {}
        }
      }
      service {
        name = "nameServer${cluster-id}"
        port = "tcp"
        check {
          type = "tcp"
          port = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }
    }

    task "connect-proxy" {
      driver = "exec"
      config {
        command = "consul"
        args = [
          "connect",
          "proxy",
          "-service",
          "namesvc-${cluster-id}-$${NOMAD_ALLOC_INDEX}",
          "-service-addr",
          "$${NOMAD_ADDR_namesvr_tcp}",
          "-listen",
          ":$${NOMAD_PORT_tcp}",
          "-register",
        ]
      }

      resources {
        network {
          port "tcp" {}
        }
      }
    }

    task "lb-backend-terraform" {
      driver = "docker"
      config {
        image = "${terraform-image}"
        command = "sh"
        args = ["/tf/tf.sh"]
        volumes = [
          "local/tf:/tf",
          "/plugin:/plugin"
        ]
      }
      resources {
        cpu = 100
        memory = 50
      }
      template {
        data = <<EOF
        set -e
        cd /tf
        cat main.tf
        terraform init -plugin-dir=/plugin
        terraform apply --auto-approve -lock=false
        tail -f /dev/null
        EOF
        destination = "local/tf/tf.sh"
        change_mode = "noop"
      }
      template {
        data = <<EOF
            terraform {
            backend "consul" {
                address = "{{with service "consul"}}{{with index . 0}}{{.Address}}:8500{{end}}{{end}}"
                scheme = "http"
                path = "namesvr-lb/${cluster-id}/namesvr-{{ env "NOMAD_ALLOC_INDEX" }}"
              }
            }

            provider "ucloud" {
              public_key = "${ucloudPubKey}"
              private_key = "${ucloudPriKey}"
              project_id = "${projectId}"
              region = "${region}"
              base_url = "${ucloud_api_base_url}"
            }

            resource "ucloud_lb_attachment" "nameServer-${cluster-id}-{{ env "NOMAD_ALLOC_INDEX" }}" {
                load_balancer_id = "${load_balancer_id}"
                listener_id      = "${nameServerListenerId}"
                resource_id      = "{{env "node.unique.name"}}"
                port             = {{ env "NOMAD_PORT_namesvr_tcp" }}
            }
            EOF
        destination = "local/tf/main.tf"
        change_mode = "noop"
      }
      //    template {
      //      data = "TF_LOG=trace"
      //      destination = "local/tf/env"
      //      env = true
      //    }
    }
  }
}