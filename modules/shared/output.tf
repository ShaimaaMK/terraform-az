output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "subnet_id" {
  value = azurerm_subnet.subnet.id
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "region" {
  description = "Région Azure utilisée"
  value       = var.region
}
output "resource_group_id" {
  description = "ID du groupe de ressources Azure"
  value       = azurerm_resource_group.rg.id
}

