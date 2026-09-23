# Mavic Drone Shop
test
An end-to-end DevOps portfolio project: a microservices e-commerce app, containerized, provisioned on AWS EKS via Terraform, deployed through GitHub Actions CI/CD, and observed with Prometheus/Grafana/Loki.

Built on top of an open-source microservices demo architecture (originally "Stan's Robot Shop"), fully restyled and rebranded here as a drone marketplace to demonstrate a realistic, multi-service DevOps pipeline — not a toy single-container app.

## What this project demonstrates
- Debugging and modifying an unfamiliar, multi-language codebase (not just infra work in isolation)
- Containerization across mixed-language microservices (Node, Java, Python, Go, PHP)
- Infrastructure as Code with Terraform (remote state, VPC, EKS, ECR, IAM/OIDC)
- CI/CD with GitHub Actions (build, vulnerability scan, push, deploy — authenticated via OIDC, no static AWS keys)
- Kubernetes deployment via Helm to AWS EKS
- Observability: Prometheus + Grafana for metrics, Loki for logs

## Architecture

| Layer | Services |
|---|---|
| **Frontend** | `web` — AngularJS (1.x), Nginx, static HTML/CSS/JS |
| **Backend services** | `cart`, `catalogue`, `user`, `payment`, `shipping`, `ratings`, `dispatch` |
| **Data tier** | MongoDB, MySQL, Redis, RabbitMQ |

```
GitHub push → GitHub Actions (build + Trivy scan + push to ECR) → deploy to EKS
                                                                          ↓
                                                Prometheus + Grafana + Loki (observability)
```

Infrastructure is provisioned by Terraform (`terraform/`), with a separate one-time `terraform/bootstrap/` step that creates the S3 + DynamoDB backend used for remote state.

## Tech stack
NodeJS (Express) · Java (Spring Boot) · Python (Flask) · Golang · PHP (Apache) · MongoDB · Redis · MySQL · RabbitMQ · Nginx · AngularJS (1.x) · Docker · Terraform · AWS EKS · GitHub Actions · Prometheus · Grafana · Loki

## Run locally
```shell
docker-compose pull
docker-compose up -d
```
App will be available at `http://localhost:8080`.

To build from source instead of pulling prebuilt images:
```shell
docker compose build
docker compose up -d
```
Edit `.env` first if you want to change the image registry/tag used for local builds.

Container images use maintained, pinned baselines: Node.js 22.14, Python 3.12.9,
Go 1.25, PHP 8.3.15, Java 11 (Corretto), Nginx 1.28, MongoDB 8.0.4,
MySQL 8.4.4, Redis 7.4.2, and RabbitMQ 4.1.3.

### Load testing
A [Locust](https://locust.io/) script is included under `load-gen/` for basic load testing against the running app.

## Deploying to AWS EKS
See `terraform/` for infrastructure provisioning and `EKS/helm/` for the Kubernetes deployment chart. High-level flow:
1. `terraform/bootstrap/` — one-time setup of the S3/DynamoDB remote state backend
2. `terraform/` — provisions the VPC, EKS cluster, ECR repositories, and GitHub Actions OIDC trust
3. GitHub Actions (`.github/workflows/`) — builds, scans, and pushes images on every push, then deploys via Helm

## Notes
- This is a portfolio/learning project, not a production system — error handling and security hardening are intentionally minimal in places inherited from the original demo app.
- Cost awareness: the EKS cluster and NAT Gateway incur hourly AWS charges while running. `terraform destroy` is used between work sessions to avoid idle cost.
