terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.60"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.5"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {
  
}

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

resource "azurerm_managed_disk" "new_os_disk_from_snapshot" {
  name                = "${var.vm_name}-spot-osdisk"
  location            = var.region
  resource_group_name = var.resource_group
  storage_account_type = "Standard_LRS"
  create_option       = "Copy"
  source_resource_id  = var.snapshot_id
  disk_size_gb        = var.os_disk_size
}



resource "azapi_resource" "new_spot_vm" {
  type      = "Microsoft.Compute/virtualMachines@2022-03-01"  
  
  name      = "${var.vm_name}-spot"
  parent_id = var.resource_group_id  
  location  = var.region
  tags      = var.tags

  body = jsonencode({
    properties = {
      hardwareProfile = {
        vmSize = var.size
      }
      priority       = "Spot"
      evictionPolicy = "Delete"  

      securityProfile = {
        securityType = "TrustedLaunch"
      }

      networkProfile = {
        networkInterfaces = [
          {
            id = azurerm_network_interface.nic.id
          }
        ]
      }

      storageProfile = {
        osDisk = {
          name         = "${var.vm_name}-spot-osdisk"
          createOption = "Attach"
          caching      = "ReadWrite"
          osType       = "Linux"
          managedDisk  = {
            id = azurerm_managed_disk.new_os_disk_from_snapshot.id
          }
        }
      }

      osProfile = {
        computerName         = "${var.vm_name}-spot"
        adminUsername        = var.admin_username
        adminPassword        = var.admin_password
        linuxConfiguration = {
          disablePasswordAuthentication = false
        }
      }
    }

    identity = {
      type = "SystemAssigned"
    }
  })

  depends_on = [
    azurerm_network_interface.nic,
    azurerm_managed_disk.new_os_disk_from_snapshot
  ]
}
resource "azapi_resource" "custom_script_extension" {
  type      = "Microsoft.Compute/virtualMachines/extensions@2022-03-01"
  name      = "customScript"
  parent_id = azapi_resource.new_spot_vm.id 
  location  = var.region

  body = jsonencode({
    properties = {
      publisher            = "Microsoft.Azure.Extensions"
      type                 = "CustomScript"
      typeHandlerVersion   = "2.1"
      autoUpgradeMinorVersion = true

      settings = {
        fileUris          = ["https://raw.githubusercontent.com/ShaimaaMK/terraform-az/main/modules/vm-spot/cloud-init.yaml"]
        commandToExecute  = "sh cloud-init.yaml"
      }
    }
  })

  depends_on = [azapi_resource.new_spot_vm]
}

