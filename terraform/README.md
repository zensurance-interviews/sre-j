# Terraform Kubernetes Nginx Deployment

This Terraform workspace deploys an nginx service to Kubernetes with support for autoscaling, ingress, and custom configurations.

## Prerequisites

- Terraform >= 1.0
- Kubernetes cluster (local or remote)
- kubectl configured with cluster access
- Valid kubeconfig file

## Quick Start

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Configure Variables (Optional)

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Deploy to Kubernetes

```bash
terraform apply
```

### 5. Verify Deployment

```bash
# Check pods
kubectl get pods -n nginx

# Check service
kubectl get svc -n nginx

# Port forward to access locally
kubectl port-forward -n nginx svc/nginx-service 8080:80
```

Access nginx at: `http://localhost:8080`

### 6. Destroy Resources

```bash
terraform destroy
```

## Configuration Options

### Basic Deployment

Default configuration deploys:
- 2 nginx replicas
- ClusterIP service on port 80
- Resource limits (100m CPU, 128Mi memory)
- Health checks (liveness + readiness probes)

### Service Types

#### ClusterIP (Default)
Internal-only access within the cluster:
```hcl
service_type = "ClusterIP"
```

#### NodePort
Access via node IP and static port:
```hcl
service_type = "NodePort"
node_port    = 30080
```
Access: `http://<node-ip>:30080`

#### LoadBalancer
Cloud load balancer (AWS ELB, GCP LB, etc.):
```hcl
service_type = "LoadBalancer"
```

### Ingress Configuration

Enable external access via Ingress controller:

```hcl
ingress_enabled    = true
ingress_host       = "nginx.example.com"
ingress_class_name = "nginx"

# Optional: Enable TLS
ingress_tls_enabled     = true
ingress_tls_secret_name = "nginx-tls"

# Optional: Add annotations
ingress_annotations = {
  "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
  "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
}
```

### Horizontal Pod Autoscaling

Enable automatic scaling based on CPU/memory:

```hcl
hpa_enabled       = true
hpa_min_replicas  = 2
hpa_max_replicas  = 10
hpa_cpu_target    = 80  # Target 80% CPU utilization
hpa_memory_target = 80  # Target 80% memory utilization
```

**Note:** Requires Kubernetes Metrics Server installed in your cluster.

### Custom Nginx Configuration

Mount custom nginx.conf via ConfigMap:

1. Create your configuration file:
```bash
cat > configs/nginx.conf <<EOF
user nginx;
worker_processes auto;
events {
    worker_connections 1024;
}
http {
    server {
        listen 80;
        location / {
            return 200 'Custom nginx configuration!';
            add_header Content-Type text/plain;
        }
    }
}
EOF
```

2. Enable in terraform.tfvars:
```hcl
custom_config_enabled = true
custom_nginx_config   = file("${path.module}/configs/nginx.conf")
```

### Resource Limits

Adjust resource requests and limits:

```hcl
cpu_request    = "200m"
cpu_limit      = "500m"
memory_request = "256Mi"
memory_limit   = "512Mi"
```

## Examples

### Example 1: Development Setup (Default)

```bash
terraform apply
```

### Example 2: Production with LoadBalancer

```bash
terraform apply \
  -var="environment=production" \
  -var="replicas=3" \
  -var="service_type=LoadBalancer" \
  -var="cpu_limit=500m" \
  -var="memory_limit=512Mi"
```

### Example 3: With Ingress and Autoscaling

```bash
terraform apply \
  -var="ingress_enabled=true" \
  -var="ingress_host=nginx.myapp.com" \
  -var="hpa_enabled=true" \
  -var="hpa_max_replicas=20"
```

### Example 4: NodePort for Local Development

```bash
terraform apply \
  -var="service_type=NodePort" \
  -var="node_port=30080"
```

## Outputs

After deployment, Terraform outputs useful information:

```bash
terraform output
```

Available outputs:
- `namespace` - Deployed namespace
- `deployment_name` - Deployment name
- `service_name` - Service name
- `service_type` - Service type
- `ingress_url` - Ingress URL (if enabled)
- `kubectl_commands` - Helpful kubectl commands

## Kubernetes Context

### Using Specific Context

```hcl
kube_context = "my-cluster-context"
```

### List Available Contexts

```bash
kubectl config get-contexts
```

### Set Current Context

```bash
kubectl config use-context my-cluster-context
```

## Verification & Troubleshooting

### Check Deployment Status

```bash
# Get all resources in namespace
kubectl get all -n nginx

# Describe deployment
kubectl describe deployment nginx -n nginx

# View pod logs
kubectl logs -l app=nginx -n nginx

# Check events
kubectl get events -n nginx --sort-by='.lastTimestamp'
```

### Test nginx

```bash
# Port forward
kubectl port-forward -n nginx svc/nginx-service 8080:80

# Test from another pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://nginx-service.nginx.svc.cluster.local
```

### Common Issues

**Issue: Pods not starting**
```bash
kubectl describe pod -l app=nginx -n nginx
kubectl logs -l app=nginx -n nginx
```

**Issue: Service not accessible**
```bash
kubectl get endpoints -n nginx
kubectl get svc nginx-service -n nginx -o yaml
```

**Issue: Ingress not working**
```bash
# Check ingress controller is installed
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl describe ingress -n nginx
```

**Issue: HPA not scaling**
```bash
# Check metrics server
kubectl get apiservices | grep metrics

# Check HPA status
kubectl get hpa -n nginx
kubectl describe hpa -n nginx
```

## Advanced Usage

### Multi-Environment Deployments

Use workspaces for multiple environments:

```bash
# Create environments
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Deploy to specific environment
terraform workspace select prod
terraform apply -var-file="prod.tfvars"
```

### State Management

For team collaboration, use remote state:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "kubernetes/nginx/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Integration with CI/CD

Example GitHub Actions workflow:

```yaml
- name: Terraform Apply
  run: |
    terraform init
    terraform plan -out=tfplan
    terraform apply tfplan
```

## Cleanup

Remove all resources:

```bash
terraform destroy
```

Or remove specific namespace:

```bash
kubectl delete namespace nginx
```
