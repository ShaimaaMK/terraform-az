admin_username = "azureuser"
admin_password = "@driaTest1998!" 
os_disk_size   = 64

image_publisher = "Canonical"
image_offer     = "UbuntuServer"
image_sku       = "24.04-LTS"
image_version   = "latest"


tags = {
  environment = "production"
  role        = "spot-vm"
}
