output "jenkins_public_ip" {
  value       = azurerm_public_ip.jenkins_public_ip.ip_address
  description = "La dirección IP pública de la VM de Jenkins."
}

output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "El servidor de inicio de sesión de Azure Container Registry."
}

output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "El nombre del clúster de Azure Kubernetes Service."
}

output "aks_kube_config" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true # Marca esto como sensible para no mostrarlo en logs fácilmente
  description = "El contenido raw del archivo kubeconfig para el clúster AKS."
}