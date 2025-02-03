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
  name                = "${var.vm_name}-osdisk"
  location            = var.region
  resource_group_name = var.resource_group
  storage_account_type = "Standard_LRS"
  create_option        = "Copy"
  source_resource_id   = var.snapshot_id
  disk_size_gb         = var.os_disk_size
}

resource "azurerm_virtual_machine" "spot_vm" {
  name                = var.vm_name
  location            = var.region
  resource_group_name = var.resource_group

  # The older VM resource uses vm_size, not "size".
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = var.size

  # Spot/eviction are valid in this older resource:
  priority        = "Spot"
  eviction_policy = "Delete"

  # OS profile for credentials
  os_profile {
    computer_name  = var.vm_name
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  # OS profile Linux config
  os_profile_linux_config {
    disable_password_authentication = false

    # custom_data belongs inside os_profile_linux_config in the older resource
    custom_data = base64encode(file("${path.module}/cloud-init.yaml"))
  }

  # Old resource calls it storage_image_reference, not source_image_reference
  # Only include this block if you also want to specify a "reference" image.
  # Usually, if you are attaching a specialized disk, you omit this. But if you
  # want both, keep it:
  storage_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  # Attach the specialized OS disk you created from the snapshot
  storage_os_disk {
    name            = "${var.vm_name}-osdisk"
    managed_disk_id = azurerm_managed_disk.os_disk_from_snapshot.id
    create_option   = "Attach"
    caching         = "ReadWrite"
  }

  # System-assigned identity
  identity {
    type = "SystemAssigned"
  }

  # Tags & lifecycle
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

# Fix the role assignment to reference azurerm_virtual_machine, not azurerm_linux_virtual_machine
resource "azurerm_role_assignment" "snapshot_creator" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_virtual_machine.spot_vm.identity[0].principal_id
}
