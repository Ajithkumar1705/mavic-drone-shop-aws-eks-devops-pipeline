# Ingress

Keep the ALB ingress outside the per-service Helm chart.

The existing project already has `EKS/helm/ingress.yaml`. Move that file here after
reviewing its exact rules. The ingress should reference the Kubernetes Service names
created by the service releases (for example `web`, `catalogue`, `cart`, etc.).

Do not put the ingress into every microservice Helm release; it is a shared cluster
routing resource.
