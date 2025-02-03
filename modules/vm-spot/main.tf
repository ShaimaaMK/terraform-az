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

resource "azapi_resource" "spot_vm" {
  type      = "Microsoft.Compute/virtualMachines@2022-03-01" # or a similar stable API version
  name      = var.vm_name
  parent_id = var.resource_group_id
  location  = var.region

  # The "body" is raw ARM JSON, so we can specify Spot + attach OS disk
  body = jsonencode({
    properties = {
      hardwareProfile = {
        vmSize = var.size
      }
      storageProfile = {
        # If you also want to specify an image reference, you can do so here
        # for non-specialized scenarios. But if your disk is fully specialized,
        # the image reference is typically omitted or just for metadata.
        imageReference = {
          publisher = var.image_publisher
          offer     = var.image_offer
          sku       = var.image_sku
          version   = var.image_version
        }
        osDisk = {
          name         = "${var.vm_name}-osdisk"
          caching      = "ReadWrite"
          createOption = "Attach"
          osType       = "Linux" # or "Windows"
          managedDisk = {
            id = azurerm_managed_disk.os_disk_from_snapshot.id
          }
        }
      }
      osProfile = {
        computerName  = var.vm_name
        adminUsername = var.admin_username
        adminPassword = var.admin_password

        linuxConfiguration = {
          disablePasswordAuthentication = false
        }

        # Cloud-init custom data in base64
        customData = base64encode(file("${path.module}/cloud-init.yaml"))
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azurerm_network_interface.nic.id
          }
        ]
      }

      # The key Spot settings below:
      priority        = "Spot"
      evictionPolicy  = "Delete"  # or "Deallocate"
      # (Optional) if you want to cap the price:
      # billingProfile = {
      #   maxPrice = -1
      # }
    }
    identity = {
      type = "SystemAssigned"
    }
  })

  # For convenience, you may want to read back the entire response from Azure:
  response_export_values = ["*"]
}

resource "azurerm_role_assignment" "snapshot_creator" {
  scope                = var.resource_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_virtual_machine.spot_vm.identity[0].principal_id
}
