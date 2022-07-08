output "external_ip_masternode" {
  value = yandex_compute_instance.k8s_masternode[0].network_interface.0.nat_ip_address
}
output "external_ip_workernode" {
  value = yandex_compute_instance.k8s_workernode[0].network_interface.0.nat_ip_address
}
