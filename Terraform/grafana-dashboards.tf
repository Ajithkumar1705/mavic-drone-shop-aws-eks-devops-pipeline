# grafana-dashboards.tf
#
# kube-prometheus-stack's Grafana deployment includes a sidecar container
# that watches for ConfigMaps labeled grafana_dashboard: "1" in the release
# namespace, and auto-loads any JSON found in them into Grafana — no manual
# "import dashboard" click in the UI, and no separate dashboard-provisioning
# tool needed. This is the standard, reproducible way to ship custom
# dashboards alongside the chart itself.

resource "kubernetes_config_map" "app_dashboard" {
  metadata {
    name      = "mavic-drone-shop-app-dashboard"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "mavic-drone-shop-app-metrics.json" = file("${path.module}/dashboards/mavic-drone-shop-app-metrics.json")
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
