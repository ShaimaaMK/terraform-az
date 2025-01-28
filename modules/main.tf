provider "azurerm" {
  features {}
}

# Module partagé pour les ressources Azure communes
module "shared" {
  source         = "./shared"
  resource_group = var.resource_group
  region         = var.region
}

# Module pour recréer une VM Spot basée sur un snapshot
module "vm_spot" {
  source            = "./vm-spot"
  resource_group    = module.shared.resource_group_name
  region            = module.shared.region
  vm_name           = var.vm_name
  size              = var.size
  admin_username    = var.admin_username
  admin_password    = var.admin_password
  os_disk_size      = var.os_disk_size
  image_publisher   = var.image_publisher
  image_offer       = var.image_offer
  image_sku         = var.image_sku
  image_version     = var.image_version
  snapshot_id       = var.snapshot_id
  subnet_id         = module.shared.subnet_id
  public_ip_id      = "" # Pas d'adresse IP publique partagée
  resource_group_id =  module.shared.resource_group_id
  tags              = var.tags
}
