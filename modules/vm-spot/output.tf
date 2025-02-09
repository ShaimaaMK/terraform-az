output "vm_id" {
  description = "ID de la VM Spot recréée"
  value       = azapi_resource.new_spot_vm.id
}

output "snapshot_id" {
  description = "ID du snapshot utilisé"
  value       = azurerm_managed_disk.new_os_disk_from_snapshot.id
}

output "public_ip" {
  description = "Adresse IP publique de la VM recréée"
  value       = azurerm_public_ip.pip.ip_address
}

