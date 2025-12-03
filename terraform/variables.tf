# Kubernetes Configuration
variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = ""
}

# Namespace
variable "namespace" {
  description = "Kubernetes namespace for nginx deployment"
  type        = string
  default     = "nginx"
}

variable "environment" {
  description = "Environment name for labeling"
  type        = string
  default     = "development"
}

# Deployment
variable "deployment_name" {
  description = "Name of the nginx deployment"
  type        = string
  default     = "nginx"
}

variable "replicas" {
  description = "Number of nginx replicas"
  type        = number
  default     = 2
  
  validation {
    condition     = var.replicas > 0
    error_message = "Replicas must be greater than 0"
  }
}

# Resources
variable "cpu_request" {
  description = "CPU request for nginx container"
  type        = string
  default     = "100m"
}

variable "cpu_limit" {
  description = "CPU limit for nginx container"
  type        = string
  default     = "200m"
}

variable "memory_request" {
  description = "Memory request for nginx container"
  type        = string
  default     = "256Mi"
}

variable "memory_limit" {
  description = "Memory limit for nginx container"
  type        = string
  default     = "512Mi"
}

# Service
variable "service_name" {
  description = "Name of the Kubernetes service"
  type        = string
  default     = "nginx-service"
}

variable "service_type" {
  description = "Type of Kubernetes service (ClusterIP, NodePort, LoadBalancer)"
  type        = string
  default     = "ClusterIP"
  
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "Service type must be ClusterIP, NodePort, or LoadBalancer"
  }
}

variable "service_port" {
  description = "Service port"
  type        = number
  default     = 80
}

variable "node_port" {
  description = "NodePort for service (only used if service_type is NodePort)"
  type        = number
  default     = 30080
  
  validation {
    condition     = var.node_port >= 30000 && var.node_port <= 32767
    error_message = "NodePort must be between 30000 and 32767"
  }
}

# Custom Configuration
variable "custom_config_enabled" {
  description = "Enable custom nginx configuration via ConfigMap"
  type        = bool
  default     = false
}

variable "custom_nginx_config" {
  description = "Custom nginx.conf content"
  type        = string
  default     = ""
}

# Ingress
variable "ingress_enabled" {
  description = "Enable Ingress for external access"
  type        = bool
  default     = false
}

variable "ingress_class_name" {
  description = "Ingress class name (e.g., nginx, traefik)"
  type        = string
  default     = "nginx"
}

variable "ingress_host" {
  description = "Hostname for Ingress"
  type        = string
  default     = "nginx.example.com"
}

variable "ingress_annotations" {
  description = "Annotations for Ingress"
  type        = map(string)
  default     = {}
}

variable "ingress_tls_enabled" {
  description = "Enable TLS for Ingress"
  type        = bool
  default     = false
}

variable "ingress_tls_secret_name" {
  description = "Name of TLS secret for Ingress"
  type        = string
  default     = "nginx-tls"
}

# Horizontal Pod Autoscaler
variable "hpa_enabled" {
  description = "Enable Horizontal Pod Autoscaler"
  type        = bool
  default     = false
}

variable "hpa_min_replicas" {
  description = "Minimum number of replicas for HPA"
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum number of replicas for HPA"
  type        = number
  default     = 10
}

variable "hpa_cpu_target" {
  description = "Target CPU utilization percentage for HPA"
  type        = number
  default     = 80
}

variable "hpa_memory_target" {
  description = "Target memory utilization percentage for HPA"
  type        = number
  default     = 80
}
