terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

locals {
  namespace = "default"
}

# Namespace
resource "kubernetes_namespace" "sre_interview" {
  metadata {
    name = local.namespace

    labels = {
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}

# Deployment for nginx
resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = var.deployment_name
    namespace = local.namespace
    labels = {
      app         = "nginx"
      environment = var.environment
      managed_by  = "terraform"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app         = "nginx"
          environment = var.environment
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "localhost:5000/zen-svc"

          port {
            name           = "http"
            container_port = 3000
            protocol       = "TCP"
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          # Optional: Mount custom nginx configuration
          dynamic "volume_mount" {
            for_each = var.custom_config_enabled ? [1] : []
            content {
              name       = "nginx-config"
              mount_path = "/etc/nginx/nginx.conf"
              sub_path   = "nginx.conf"
              read_only  = true
            }
          }
        }

        # Optional: Custom configuration volume
        dynamic "volume" {
          for_each = var.custom_config_enabled ? [1] : []
          content {
            name = "nginx-config"
            config_map {
              name = kubernetes_config_map.nginx_config[0].metadata[0].name
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.sre_interview]
}

# Service for nginx
resource "kubernetes_service" "nginx" {
  metadata {
    name      = var.service_name
    namespace = local.namespace

    labels = {
      app         = "nginx"
      environment = var.environment
      managed_by  = "terraform"
    }
  }

  spec {
    type = var.service_type

    selector = {
      app = "nginx"
    }

    port {
      name        = "http"
      port        = var.service_port
      target_port = 80
      protocol    = "TCP"
      node_port   = var.service_type == "NodePort" ? var.node_port : null
    }
  }

  depends_on = [kubernetes_deployment.nginx, kubernetes_namespace.sre_interview]
}

# Optional: ConfigMap for custom nginx configuration
resource "kubernetes_config_map" "nginx_config" {
  count = var.custom_config_enabled ? 1 : 0

  metadata {
    name      = "${var.deployment_name}-config"
    namespace = local.namespace

    labels = {
      app         = "nginx"
      environment = var.environment
      managed_by  = "terraform"
    }
  }

  data = {
    "nginx.conf" = var.custom_nginx_config
  }

}

# Optional: Ingress for external access
resource "kubernetes_ingress_v1" "nginx" {
  count = var.ingress_enabled ? 1 : 0

  metadata {
    name      = "${var.deployment_name}-ingress"
    namespace = local.namespace

    annotations = var.ingress_annotations

    labels = {
      app         = "nginx"
      environment = var.environment
      managed_by  = "terraform"
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.ingress_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.nginx.metadata[0].name
              port {
                number = var.service_port
              }
            }
          }
        }
      }
    }

    dynamic "tls" {
      for_each = var.ingress_tls_enabled ? [1] : []
      content {
        hosts       = [var.ingress_host]
        secret_name = var.ingress_tls_secret_name
      }
    }
  }

  depends_on = [kubernetes_service.nginx]
}

# Optional: HorizontalPodAutoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "nginx" {
  count = var.hpa_enabled ? 1 : 0

  metadata {
    name      = "${var.deployment_name}-hpa"
    namespace = local.namespace

    labels = {
      app         = "nginx"
      environment = var.environment
      managed_by  = "terraform"
    }
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.nginx.metadata[0].name
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_target
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_memory_target
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.nginx]
}
