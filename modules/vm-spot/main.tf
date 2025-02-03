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
  name                = "${var.vm_name}-spot"
  location            = var.region
  resource_group_name = var.resource_group

  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = var.size

  #spot_instance_enabled = true
  #eviction_policy       = "Delete"

  os_profile {
    computer_name  = var.vm_name
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data = base64encode(file("${path.module}/cloud-init.yaml"))
  }

  os_profile_linux_config {
    disable_password_authentication = false
    
  }


  storage_os_disk {
    name            = "${var.vm_name}-osdisk"
    managed_disk_id = azurerm_managed_disk.os_disk_from_snapshot.id
    create_option   = "Attach"
    caching         = "ReadWrite"
    os_type         = "Linux"
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
provisioner "local-exec" {
  command = <<EOT
    az vm update \
      --resource-group ${var.resource_group} \
      --name ${self.name} \
      --set priority=Spot \
      evictionPolicy=Deallocate \
      billingProfile.maxPrice=-1
  EOT
}
}

resource "azurerm_role_assignment" "snapshot_creator" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_virtual_machine.spot_vm.identity[0].principal_id
}
