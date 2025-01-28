resource "azurerm_public_ip" "pip" {
  name                = "${var.vm_name}-pip"
  location            = var.region
  resource_group_name = var.resource_group
  allocation_method   = "Static"
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
  name                = "${var.vm_name}-osdisk-${timestamp()}"
  location            = var.region
  resource_group_name = var.resource_group
  storage_account_type = "Standard_LRS"
  create_option        = "Copy"
  source_resource_id   = var.snapshot_id
  disk_size_gb         = var.os_disk_size
}

resource "azurerm_linux_virtual_machine" "spot_vm" {
  name                = var.vm_name
  location            = var.region
  resource_group_name = var.resource_group
  size                = var.size

  admin_username                  = var.admin_username
  disable_password_authentication = false
  admin_password                  = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  priority        = "Spot"
  eviction_policy = "Delete"

  storage_os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    managed_disk_id      = azurerm_managed_disk.os_disk_from_snapshot.id
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  custom_data = base64encode(file("${path.module}/cloud-init.yaml"))

  os_profile_linux_config {
    disable_password_authentication = false
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

resource "azurerm_role_assignment" "snapshot_creator" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor" # Recommandé de créer un rôle personnalisé avec des permissions limitées
  principal_id         = azurerm_linux_virtual_machine.spot_vm.identity[0].principal_id
}
