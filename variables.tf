variable "vm_name" {
  description = "Nom de la VM Spot à recréer"
  type        = string
}

variable "size" {
  description = "Taille de la VM Spot "
  type        = string
}

variable "region" {
  description = "Région Azure "
  type        = string
}

variable "os_disk_size" {
  description = "Taille du disque OS"
  type        = number
  default     = 64
}

variable "admin_username" {
  description = "Nom d'utilisateur administrateur"
  type        = string
  default     = "shama"
}

variable "admin_password" {
  description = "Mot de passe administrateur"
  type        = string
  default   = "Str0ngP@ssw0rd!"
}
