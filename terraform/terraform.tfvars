location             = "eastus"
resource_group_name  = "taller-rg"
acr_name             = "duxtalleracr"
acr_sku              = "Basic" # O "Standard", "Premium"
aks_name             = "duxtalleraks"
vm_name              = "jenkins-vm"
jenkins_vm_size      = "Standard_B2s" # Puedes cambiarlo a un tamaño más grande si es necesario
admin_username       = "azureuser"
ssh_public_key_path  = "~/.ssh/id_rsa_jenkins.pub"
jenkins_public_ip_name = "jenkins-public-ip"
jenkins_nsg_name     = "jenkins-nsg"