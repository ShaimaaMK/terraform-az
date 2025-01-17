variable "vm_name" {
  description = "Nom de la VM Spot à recréer"
  type        = string
}

variable "size" {
  description = "Taille de la VM Spot"
  type        = string
}

variable "region" {
  description = "Région Azure"
  type        = string
}

variable "os_disk_size" {
  description = "Taille du disque OS"
  type        = number
  default     = 64
}

variable "os_type"{
  description = "type du os windows/linux"
  type = string
  default = "Linux"
}

variable "resource_group" {
  description = "Nom du groupe de ressources"
  type        = string
  default     = "rg-spot-vms" 
}

variable "admin_username" {
  description = "Nom d'utilisateur administrateur"
  type        = string
  default     = "shama"
}

variable "admin_password" {
  description = "Mot de passe administrateur"
  type        = string
  default     = "Str0ngP@ssw0rd!"
}

variable "image_publisher" {
  description = "Publisher de l'image de la VM"
  type        = string
  default     = "Canonical"  
}

variable "image_offer" {
  description = "Offer de l'image de la VM"
  type        = string
  default     = "0001-com-ubuntu-confidential-vm-focal"  
}

variable "image_sku" {
  description = "SKU de l'image de la VM"
  type        = string
  default     = "20_04-lts-cvm"
}

variable "image_version" {
  description = "Version de l'image de la VM"
  type        = string
  default     = "20.04.202111100"
}
