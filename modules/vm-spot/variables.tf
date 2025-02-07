variable "resource_group" {
  description = "Nom du groupe de ressources Azure"
  type        = string
}

variable "region" {
  description = "Région Azure"
  type        = string
}

variable "vm_name" {
  description = "Nom de la VM Spot"
  type        = string
}

variable "size" {
  description = "Taille de la VM (ex: Standard_D2s_v3)"
  type        = string
}

variable "admin_username" {
  description = "Nom d'utilisateur administrateur"
  type        = string
}

variable "admin_password" {
  description = "Mot de passe administrateur"
  type        = string
  sensitive   = true
}

variable "os_disk_size" {
  description = "Taille du disque OS en Go"
  type        = number
  default     = 64
}

variable "image_publisher" {
  description = "Publisher de l'image"
  type        = string
}

variable "image_offer" {
  description = "Offer de l'image"
  type        = string
}

variable "image_sku" {
  description = "SKU de l'image"
  type        = string
}

variable "image_version" {
  description = "Version de l'image"
  type        = string
}

variable "snapshot_id" {
  description = "ID du snapshot pour reprovisionner la VM"
  type        = string
}

variable "subnet_id" {
  description = "ID du subnet Azure"
  type        = string
}

variable "public_ip_id" {
  description = "ID de l'adresse IP publique statique"
  type        = string
}

variable "resource_group_id" {
  description = "ID du groupe de ressources Azure"
  type        = string
}

variable "tags" {
  description = "Tags associés à la VM"
  type        = map(string)
  default     = {}
}
