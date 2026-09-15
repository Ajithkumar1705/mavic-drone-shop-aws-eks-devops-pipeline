resource "kubernetes_namespace" "app" {
  metadata {
    name = "mavic-drone-shop"
  }
}

resource "kubernetes_role" "servicemonitor_manager" {
  metadata {
    name      = "servicemonitor-manager"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  rule {
    api_groups = ["monitoring.coreos.com"]
    resources  = ["servicemonitors"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }
}

resource "kubernetes_role_binding" "github_actions_servicemonitor" {
  metadata {
    name      = "github-actions-servicemonitor-binding"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.servicemonitor_manager.metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "github-actions-deploy"
    api_group = "rbac.authorization.k8s.io"
  }
}