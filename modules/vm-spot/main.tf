resource "azurerm_public_ip" "pip" {
  name                = "${var.vm_name}-pip"
  location            = var.region
  resource_group_name = var.resource_group
  allocation_method   = "Static"

  tags = merge(
    {
      managed_by = "terraform"
    },
    var.tags
  )
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.region
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  tags = merge(
    {
      managed_by = "terraform"
    },
    var.tags
  )
}

resource "azurerm_managed_disk" "os_disk_from_snapshot" {
  name                    = "${var.vm_name}-osdisk"
  location                = var.region
  resource_group_name     = var.resource_group
  storage_account_type    = "Standard_LRS"
  create_option           = "Copy"
  source_resource_id      = var.snapshot_id
  disk_size_gb            = var.os_disk_size
}

resource "azurerm_virtual_machine" "spot_vm" {
  name                = "${var.vm_name}-spot"
  location            = var.region
  resource_group_name = var.resource_group

  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = var.size

  # Bloc storage_os_disk pour spécifier le disque attaché
  storage_os_disk {
    name            = "${var.vm_name}-osdisk"
    managed_disk_id = azurerm_managed_disk.os_disk_from_snapshot.id  # Référence au disque géré
    create_option   = "Attach"  # Indique que nous attachons un disque existant
    caching         = "ReadWrite"
    os_type         = "Linux"  # Type du système d'exploitation
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(
    {
      managed_by = "terraform"
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Utilisation de null_resource pour mettre à jour la VM et appliquer les configurations Spot et Trusted Launch
resource "null_resource" "update_vm_security_and_attach_disk" {
  provisioner "local-exec" {
    command = <<EOT
      # Mettre à jour la VM pour la rendre Spot
      az vm update \
        --resource-group ${var.resource_group} \
        --name ${azurerm_virtual_machine.spot_vm.name} \
        --set priority=Spot \
        --set evictionPolicy=Deallocate  # Utiliser Deallocate pour la politique d'éviction

      # Appliquer le type de sécurité Trusted Launch
      az vm update \
        --resource-group ${var.resource_group} \
        --name ${azurerm_virtual_machine.spot_vm.name} \
        --set securityProfile.securityType="TrustedLaunch"

      # Attacher le disque après mise à jour
      az vm disk attach \
        --resource-group ${var.resource_group} \
        --vm-name ${azurerm_virtual_machine.spot_vm.name} \
        --name ${azurerm_managed_disk.os_disk_from_snapshot.name}
    EOT
  }

  depends_on = [
    azurerm_virtual_machine.spot_vm,
    azurerm_managed_disk.os_disk_from_snapshot
  ]
}

resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "${azurerm_virtual_machine.spot_vm.name}-cse"
  virtual_machine_id   = azurerm_virtual_machine.spot_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    fileUris  = ["https://raw.githubusercontent.com/ShaimaaMK/terraform-az/main/modules/vm-spot/cloud-init.yaml"]
    commandToExecute = "sh cloud-init.yaml"
  })
  
  tags = merge(
    {
      managed_by = "terraform"
    },
    var.tags
  )
}

resource "azurerm_role_assignment" "snapshot_creator" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_virtual_machine.spot_vm.identity[0].principal_id
}
