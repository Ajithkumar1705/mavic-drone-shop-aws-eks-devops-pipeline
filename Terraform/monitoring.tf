# monitoring.tf
#
# Installs kube-prometheus-stack (Prometheus + Grafana + Alertmanager +
# node-exporter + kube-state-metrics) via its official Helm chart, using
# the same Terraform-managed helm_release pattern as alb-controller.tf.
#
# NOTE ON SIZING: this cluster runs on 2x t3.medium nodes (4 vCPU / 8GB RAM
# total) alongside 10 running app services. kube-prometheus-stack's chart
# defaults are tuned for larger clusters and WILL cause resource pressure
# or Pending pods if left at defaults here. The resource requests/limits
# and retention period below are deliberately reduced for a small demo
# cluster — this is a conscious trade-off (short retention, single
# replicas, no persistent storage for Alertmanager), not a production
# configuration. Increase these if you resize the node group later.

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "62.7.0" # check https://github.com/prometheus-community/helm-charts for a newer version later
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # Prometheus itself
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "6h" # short retention — this is a demo cluster you destroy between sessions, not a long-lived environment
  }
  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "256Mi"
  }
  set {
    name  = "prometheus.prometheusSpec.resources.limits.memory"
    value = "512Mi"
  }

  # Grafana
  set {
    name  = "grafana.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "grafana.resources.requests.memory"
    value = "128Mi"
  }
  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  # Alertmanager — kept, since a real alert rule is part of demonstrating
  # actual monitoring, not just dashboards nobody looks at
  set {
    name  = "alertmanager.alertmanagerSpec.resources.requests.cpu"
    value = "25m"
  }
  set {
    name  = "alertmanager.alertmanagerSpec.resources.requests.memory"
    value = "64Mi"
  }

  depends_on = [kubernetes_namespace.monitoring]
}
