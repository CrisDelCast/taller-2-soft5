# Bloque de configuración del Backend de Terraform (¡MUY IMPORTANTE para entornos reales!)
# Esto almacena el estado de Terraform de forma remota en una cuenta de almacenamiento de Azure.
# ¡IMPORTANTE!: Reemplaza 'nombretuacuentadealmacenamiento', 'nombretucontenedordeestado'
# y 'nombretuterrastatekey' con tus propios valores.
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.0" # Se recomienda fijar la versión del proveedor
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-estado"        # Crea un RG solo para el estado si no existe
    storage_account_name = "crisdterraformbackend001" # Crea esta cuenta de almacenamiento
    container_name       = "contenedordeestado"  # Crea este contenedor dentro de la cuenta
    key                  = "taller-jenkins-aks.tfstate" # Nombre del archivo de estado
  }
}

provider "azurerm" {
  features {}
  # Opcional: Puedes especificar la suscripción si no quieres depender de 'az account set'
  # subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku # Usa la variable acr_sku
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "duxtaller"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "standard_b2s"
  }

  identity {
    type = "SystemAssigned"
  }

  # Opcional: Configuración de diagnóstico para AKS
  # addon_profile {
  #   oms_agent {
  #     enabled = true
  #     log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_la.id
  #   }
  # }
}

# Recursos de Red para la VM de Jenkins
resource "azurerm_virtual_network" "main" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# IP Pública para Jenkins
resource "azurerm_public_ip" "jenkins_public_ip" {
  name                = var.jenkins_public_ip_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static" # IP estática para que no cambie al reiniciar
  sku                 = "Standard" # SKU recomendado para IPs públicas
}

resource "azurerm_network_interface" "jenkins_nic" {
  name                = "jenkins-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins_public_ip.id # Asocia la IP pública
  }
}

# Grupo de Seguridad de Red (NSG) para la VM de Jenkins
resource "azurerm_network_security_group" "jenkins_nsg" {
  name                = var.jenkins_nsg_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Regla para permitir SSH (Puerto 22)
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "0.0.0.0/0" # ¡ADVERTENCIA!: Permite SSH desde cualquier IP. En producción, limita a IPs conocidas.
    destination_address_prefix = "*"
  }

  # Regla para permitir HTTP (Puerto 80 - si Jenkins usa HTTP)
  security_rule {
    name                       = "HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "0.0.0.0/0" # ¡ADVERTENCIA!: Permite HTTP desde cualquier IP.
    destination_address_prefix = "*"
  }

  # Regla para permitir HTTPS (Puerto 443 - si Jenkins usa HTTPS)
  security_rule {
    name                       = "HTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "0.0.0.0/0" # ¡ADVERTENCIA!: Permite HTTPS desde cualquier IP.
    destination_address_prefix = "*"
  }
}

# Asociación del NSG a la Interfaz de Red de Jenkins
resource "azurerm_network_interface_security_group_association" "jenkins_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.jenkins_nic.id
  network_security_group_id = azurerm_network_security_group.jenkins_nsg.id
}


resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.jenkins_vm_size # Usa la variable para el tamaño
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.jenkins_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }
}