variable "location" {
  default     = "eastus"
  description = "La región de Azure donde se desplegarán los recursos."
}

variable "resource_group_name" {
  default     = "taller-rg"
  description = "El nombre del Grupo de Recursos de Azure."
}

variable "acr_name" {
  default     = "duxtalleracr"
  description = "El nombre de Azure Container Registry."
}

variable "acr_sku" {
  default     = "Basic"
  description = "El SKU de Azure Container Registry (Basic, Standard, Premium)."
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "El SKU de ACR debe ser 'Basic', 'Standard' o 'Premium'."
  }
}

variable "aks_name" {
  default     = "duxtalleraks"
  description = "El nombre de Azure Kubernetes Service."
}

variable "vm_name" {
  default     = "jenkins-vm"
  description = "El nombre de la máquina virtual de Jenkins."
}

variable "admin_username" {
  default     = "azureuser"
  description = "El nombre de usuario administrador para la VM de Jenkins."
}

variable "ssh_public_key_path" {
  default     = "~/.ssh/id_rsa_jenkins"
  description = "La ruta al archivo de clave pública SSH para la VM de Jenkins."
}

variable "jenkins_public_ip_name" {
  default     = "jenkins-public-ip"
  description = "El nombre de la dirección IP pública para la VM de Jenkins."
}

variable "jenkins_nsg_name" {
  default     = "jenkins-nsg"
  description = "El nombre del Grupo de Seguridad de Red para la VM de Jenkins."
}

variable "jenkins_vm_size" {
  default     = "Standard_B2s"
  description = "El tamaño de la máquina virtual de Jenkins."
  validation {
    condition     = var.jenkins_vm_size != "" // Solo una validación de ejemplo, puedes añadir más restricciones de tamaño aquí
    error_message = "El tamaño de la VM de Jenkins no puede estar vacío."
  }
}