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


resource "azurerm_virtual_machine" "spot_vm" {
  name                = "${var.vm_name}-spot"
  location            = var.region
  resource_group_name = var.resource_group
  

  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = var.size

  #spot_instance_enabled = true
  #eviction_policy       = "Delete"

#  os_profile {
 #   computer_name  = var.vm_name
  #  admin_username = var.admin_username
  #  admin_password = var.admin_password
  #  custom_data = base64encode(file("${path.module}/cloud-init.yaml"))
 # }

 # os_profile_linux_config {
  #  disable_password_authentication = false
    
 # }
  


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

  resource "null_resource" "update_vm_security_and_attach_disk" {
  provisioner "local-exec" {
    command = <<EOT

      az vm update \
        --resource-group ${var.resource_group} \
        --name ${azurerm_virtual_machine.spot_vm.name} \
        --set priority=Spot \
        --set evictionPolicy=Delete

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


}

resource "azurerm_virtual_machine_extension" "custom_script" {
  name                 = "${azurerm_virtual_machine.spot_vm.name}-cse"
  virtual_machine_id   = azurerm_virtual_machine.spot_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    fileUris  =        ["https://raw.githubusercontent.com/ShaimaaMK/terraform-az/main/modules/vm-spot/cloud-init.yaml"]
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
