output "public_ips" {
  value = ucloud_eip.nomad_servers.*.public_ip
}

output "lb_id" {
  value = module.nomad_server_lb.lb_id
}

output "lb_ip" {
  value = module.nomad_server_lb.lb_ip
}