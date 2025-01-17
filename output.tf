output "resource_group" {
  description = "Nom du groupe de ressources utilisé"
  value       = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  description = "Adresse IP publique de la VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "admin_username" {
  description = "Nom d'utilisateur pour la VM"
  value       = var.admin_username
}

output "vm_id" {
  description = "ID de la VM Spot"
  value       = azurerm_linux_virtual_machine.spot_vm.id
}
