variable "vm_version" {
  type        = string
  default     = "1.0.0"
  description = "Versione dell'immagine — usata nel nome del file di output"
}

variable "iso_url" {
  type        = string
  default     = "https://cdimage.kali.org/kali-2026.1/kali-linux-2026.1-installer-amd64.iso"
  description = "URL dell'ISO Kali Linux installer (aggiorna iso_checksum di conseguenza)"
}

variable "iso_checksum" {
  type        = string
  default     = "file:https://cdimage.kali.org/kali-2026.1/SHA256SUMS"
  description = "Checksum verificato sul file SHA256SUMS ufficiale di Kali"
}

variable "vm_user" {
  type        = string
  default     = "vapt"
  description = "Utente principale della VM"
}

variable "vm_password" {
  type        = string
  default     = "vapt"
  sensitive   = true
  description = "Password dell'utente — cambia prima di distribuire la VM (PKR_VAR_vm_password)"
}

variable "cpus" {
  type        = number
  default     = 4
  description = "CPU assegnate alla VM durante il build"
}

variable "memory" {
  type        = number
  default     = 8192
  description = "RAM in MB assegnata durante il build"
}

variable "disk_size" {
  type        = number
  default     = 81920
  description = "Dimensione disco in MB (default: 80 GB)"
}
