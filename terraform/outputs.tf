
output "deployment_name" {
  description = "Name of the nginx deployment"
  value       = kubernetes_deployment.nginx.metadata[0].name
}

output "service_name" {
  description = "Name of the nginx service"
  value       = kubernetes_service.nginx.metadata[0].name
}

output "service_type" {
  description = "Type of the nginx service"
  value       = kubernetes_service.nginx.spec[0].type
}

output "service_port" {
  description = "Port of the nginx service"
  value       = kubernetes_service.nginx.spec[0].port[0].port
}

output "node_port" {
  description = "NodePort of the nginx service (if applicable)"
  value       = var.service_type == "NodePort" ? kubernetes_service.nginx.spec[0].port[0].node_port : null
}

output "replicas" {
  description = "Number of nginx replicas"
  value       = kubernetes_deployment.nginx.spec[0].replicas
}

output "ingress_enabled" {
  description = "Whether Ingress is enabled"
  value       = var.ingress_enabled
}

output "ingress_host" {
  description = "Ingress hostname (if enabled)"
  value       = var.ingress_enabled ? var.ingress_host : null
}

output "ingress_url" {
  description = "Full URL to access nginx via Ingress (if enabled)"
  value       = var.ingress_enabled ? (var.ingress_tls_enabled ? "https://${var.ingress_host}" : "http://${var.ingress_host}") : null
}

output "hpa_enabled" {
  description = "Whether HPA is enabled"
  value       = var.hpa_enabled
}

# output "kubectl_commands" {
#   description = "Useful kubectl commands"
#   value = {
#     get_pods     = "kubectl get pods -n ${kubernetes_namespace.nginx.metadata[0].name}"
#     get_service  = "kubectl get service -n ${kubernetes_namespace.nginx.metadata[0].name}"
#     get_ingress  = "kubectl get ingress -n ${kubernetes_namespace.nginx.metadata[0].name}"
#     describe_pod = "kubectl describe pod -l app=nginx -n ${kubernetes_namespace.nginx.metadata[0].name}"
#     logs         = "kubectl logs -l app=nginx -n ${kubernetes_namespace.nginx.metadata[0].name}"
#     port_forward = "kubectl port-forward -n ${kubernetes_namespace.nginx.metadata[0].name} svc/${kubernetes_service.nginx.metadata[0].name} 8080:80"
#   }
# }
