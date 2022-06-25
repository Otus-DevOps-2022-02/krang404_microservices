output "external_ip_0" {
  value = yandex_compute_instance.logging[0].network_interface.0.nat_ip_address
}
# output "external_ip_1" {
#   value = yandex_compute_instance.docker[1].network_interface.0.nat_ip_address
# }
