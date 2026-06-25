# 🤖 SentimentAI

> REST API for sentiment analysis — Full DevOps pipeline with FastAPI, Docker, Jenkins, SonarQube, Trivy, Terraform, Prometheus & Grafana

[![Pipeline](https://img.shields.io/badge/CI%2FCD-Jenkins-blue?logo=jenkins)](http://localhost:8080)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker)](https://github.com/afif-yassine/sentiment-ai/pkgs/container/sentiment-ai)
[![Python](https://img.shields.io/badge/Python-3.11-yellow?logo=python)](https://www.python.org/)
[![SonarQube](https://img.shields.io/badge/SonarQube-passed-brightgreen?logo=sonarqube)](http://localhost:9000)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)](https://www.terraform.io/)
[![Prometheus](https://img.shields.io/badge/Monitoring-Prometheus-E6522C?logo=prometheus)](http://localhost:9090)
[![Grafana](https://img.shields.io/badge/Dashboard-Grafana-F46800?logo=grafana)](http://localhost:3000)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📋 Overview

SentimentAI is a REST API that receives a text input, analyzes it, and returns a sentiment label
(**POSITIVE**, **NEGATIVE**, or **NEUTRAL**) with a confidence score between 0 and 1.

This project implements a complete production-grade DevOps pipeline:

| TP | Topic | Status |
|----|-------|--------|
| TP1 | Git + Docker + Compose | ✅ Done |
| TP2 | Jenkins Pipeline (build + test + push) | ✅ Done |
| TP3 | SonarQube + Trivy (Quality & Security) | ✅ Done |
| TP4 | Terraform IaC + Docker provider | ✅ Done |
| TP5 | Monitoring with Prometheus + Grafana | ✅ Done |

---

## 🏗️ Project Structure

```
sentiment-ai/
├── src/
│   ├── __init__.py
│   ├── main.py              # FastAPI app + Prometheus metrics
│   ├── model.py             # Sentiment analysis model
│   └── schemas.py           # Pydantic data models
├── tests/
│   ├── __init__.py
│   └── test_api.py          # Unit & integration tests (88% coverage)
├── monitoring/
│   ├── prometheus.yml       # Prometheus scrape configuration
│   ├── alerts.yml           # Alerting rules
│   └── docker-compose.yml   # Prometheus + Grafana stack
├── infra/
│   ├── main.tf              # Terraform Docker provider + staging container
│   ├── monitoring.tf        # Terraform image references (Prometheus/Grafana)
│   ├── variables.tf         # Input variables (image_tag, docker_host, etc.)
│   └── outputs.tf           # app_url, container_id, network_name
├── .github/
│   └── workflows/           # GitHub Actions (placeholder)
├── Dockerfile               # Container definition (python:3.11-slim)
├── docker-compose.yml       # Local development stack
├── Jenkinsfile              # CI/CD pipeline (11 stages)
├── Makefile                 # Automation commands
└── requirements.txt         # Pinned Python dependencies
```

---

## 🚀 Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows)
- [Git](https://git-scm.com/)
- [Terraform](https://www.terraform.io/downloads) >= 1.0

### 1. Clone the repository

```bash
git clone https://github.com/afif-yassine/sentiment-ai.git
cd sentiment-ai
```

### 2. Run the API locally with Docker Compose

```bash
docker compose up -d
```

API available at **http://localhost:8080**

### 3. Test the API

```bash
# Health check
curl http://localhost:8080/health
# {"status": "ok"}

# Sentiment prediction
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Ce produit est excellent !"}'
# {"label":"POSITIVE","score":0.7,"text":"Ce produit est excellent !"}

# Prometheus metrics
curl http://localhost:8080/metrics | grep sentiment
```

### 4. Run tests

```bash
make test
```

---

## 📡 API Endpoints

### `GET /health`

```bash
curl http://localhost:8080/health
```
```json
{"status": "ok"}
```

### `POST /predict`

```bash
curl -X POST http://localhost:8080/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Ce produit est vraiment bien"}'
```
```json
{
  "label": "POSITIVE",
  "score": 0.7,
  "text": "Ce produit est vraiment bien"
}
```

| Field | Type | Values |
|-------|------|--------|
| `label` | string | `POSITIVE`, `NEGATIVE`, `NEUTRAL` |
| `score` | float | 0.0 – 1.0 |
| `text` | string | Original input text |

### `GET /metrics`

Exposes Prometheus metrics at **http://localhost:8080/metrics**

Key metrics:
| Metric | Type | Description |
|--------|------|-------------|
| `sentiment_predictions_total` | Counter | Total predictions by label and status |
| `sentiment_confidence_score` | Gauge | Last prediction confidence score |
| `sentiment_prediction_duration_seconds` | Histogram | Prediction duration in seconds |
| `http_requests_total` | Counter | HTTP requests by method/handler/status |

---

## 🐳 Docker

### Build

```bash
docker build -t sentiment-ai:latest .
```

### Run

```bash
docker run -d --name sentiment -p 8080:8000 sentiment-ai:latest
```

### Makefile targets

| Command | Description |
|---------|-------------|
| `make build` | Build the Docker image |
| `make run` | Start with Docker Compose |
| `make test` | Run tests inside Docker |
| `make stop` | Stop the stack |
| `make clean` | Remove containers and image |

---

## ⚙️ CI/CD Pipeline (Jenkins — 11 Stages)

The `Jenkinsfile` defines a complete 11-stage pipeline:

```
Checkout → Lint → IaC Validate → Build & Test → SonarQube Analysis →
Quality Gate → Security Scan → Push → IaC Apply → Deploy Staging → Smoke Test
```

| # | Stage | Description | Condition |
|---|-------|-------------|-----------|
| 1 | **Checkout** | Clone repo, display branch/commit | Always |
| 2 | **Lint** | flake8 on `src/` (max-line-length=100) | Always |
| 3 | **IaC Validate** | `terraform validate` + `fmt -check` | Always |
| 4 | **Build & Test** | Build image, run pytest (coverage ≥ 70%) | Always |
| 5 | **SonarQube Analysis** | Static code analysis | Always |
| 6 | **Quality Gate** | Abort if SonarQube gate fails | Always |
| 7 | **Security Scan** | Trivy image scan (HIGH/CRITICAL) | Always |
| 8 | **Push** | Push image to `ghcr.io` | main only |
| 9 | **IaC Apply** | `terraform apply` (redeploy staging) | main only |
| 10 | **Deploy Staging** | Health check on staging container | main only |
| 11 | **Smoke Test** | Verify /health, /metrics, Prometheus, Grafana | main only |

### Jenkins Setup

```bash
# 1. Create the Docker network
docker network create cicd-network

# 2. Start Jenkins
docker volume create jenkins-data
docker run -d \
  --name jenkins \
  --network cicd-network \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# 3. Start SonarQube
docker run -d \
  --name sonarqube \
  --network cicd-network \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:lts-community
```

### Required Jenkins Credentials

| Credential ID | Type | Description |
|---------------|------|-------------|
| `github-token` | Username + Password | GitHub PAT for image push |
| `sonar-token` | Secret text | SonarQube analysis token |

---

## 🏗️ Infrastructure (Terraform)

The `infra/` directory manages the staging environment with Terraform and the
[kreuzwerker/docker](https://registry.terraform.io/providers/kreuzwerker/docker/latest) provider.

### Resources managed

| Resource | Description |
|----------|-------------|
| `docker_network.cicd` | The shared `cicd-network` |
| `docker_image.sentiment` | The built SentimentAI image |
| `docker_container.sentiment_staging` | Staging container on port 8001 |

> **Note:** Prometheus and Grafana containers are managed by
> `monitoring/docker-compose.yml`, **not** by Terraform.

### Local deploy

```bash
cd infra

# First time — import existing network
NETWORK_ID=$(docker network inspect cicd-network --format "{{.Id}}")
terraform import docker_network.cicd $NETWORK_ID

# Apply
terraform apply
# App available at http://localhost:8001

# Deploy a specific image tag
terraform apply -var='image_tag=abc1234'
```

---

## 📊 Monitoring (Prometheus + Grafana)

### Start the monitoring stack

```bash
# The cicd-network must exist first
docker network create cicd-network  # skip if already exists

cd monitoring
docker compose up -d

# Verify
docker ps | grep -E 'prometheus|grafana'
```

| Service | URL | Credentials |
|---------|-----|-------------|
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3000 | admin / admin |

### Prometheus configuration

Prometheus scrapes SentimentAI every **15 seconds**:

```yaml
# monitoring/prometheus.yml
scrape_configs:
  - job_name: 'sentiment-ai'
    static_configs:
      - targets:
          - 'sentiment-staging:8000'   # Docker DNS name
    metrics_path: /metrics
```

> **Why `sentiment-staging:8000` and not `localhost:8000`?**
> Prometheus runs in a Docker container. `localhost` would refer to the
> Prometheus container itself. Docker resolves `sentiment-staging` to the
> correct container IP on `cicd-network`.

### Grafana Dashboard Setup

1. Open **http://localhost:3000** → login `admin / admin`
2. **Connections → Data sources → Add data source → Prometheus**
3. URL: `http://prometheus:9090` *(not localhost!)*
4. Click **Save & Test** → green ✅
5. **Dashboards → New → New Dashboard → Add visualization**

The 4 panels to create:

| Panel | Type | PromQL Query |
|-------|------|-------------|
| Requêtes/s | Time series | `rate(http_requests_total{handler="/predict"}[1m])` |
| Latence p99 | Time series | `histogram_quantile(0.99, rate(sentiment_prediction_duration_seconds_bucket[5m]))` |
| Taux erreurs | Stat | `rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100` |
| Confiance | Gauge | `avg(sentiment_confidence_score)` |

### Generate test traffic

```bash
# Send 50 predictions to populate metrics
for i in $(seq 1 50); do
  curl -s -X POST http://localhost:8001/predict \
    -H "Content-Type: application/json" \
    -d '{"text": "Ce produit est vraiment bien"}' > /dev/null
  sleep 0.5
done
```

### Alert rules

Three alerts are configured in `monitoring/alerts.yml`:

| Alert | Condition | Severity |
|-------|-----------|----------|
| `HighLatency` | p99 latency > 500ms for 2min | warning |
| `HighErrorRate` | 5xx error rate > 5% for 1min | critical |
| `LowConfidenceScore` | avg confidence < 0.85 for 5min | warning |

---

## 🔒 Security Scan (Trivy)

Trivy scans the Docker image for known CVEs on every build:

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
    --severity HIGH,CRITICAL \
    --exit-code 0 \
    sentiment-ai:latest
```

> `--exit-code 0` means the pipeline does **not** fail on CVEs (informational
> scan only). Change to `--exit-code 1` to enforce a hard block on CRITICAL.

---

## 🧪 Tests

```
tests/test_api.py::test_health               PASSED  [ 33%]
tests/test_api.py::test_predict_positive     PASSED  [ 66%]
tests/test_api.py::test_predict_empty_fails  PASSED  [100%]

Coverage: 88%
```

| Test | Description |
|------|-------------|
| `test_health` | Verifies `/health` returns HTTP 200 |
| `test_predict_positive` | Verifies `/predict` response structure |
| `test_predict_empty_fails` | Verifies Pydantic rejects empty text with HTTP 422 |

---

## 📦 Docker Registry

Images are published to GitHub Container Registry on every push to `main`:

```bash
docker pull ghcr.io/afif-yassine/sentiment-ai:latest
docker pull ghcr.io/afif-yassine/sentiment-ai:<git-sha>
```

---

## 🔄 Full Pipeline Flow

```
git push origin main
       │
       ▼
  Jenkins (webhook/poll)
       │
       ├─ 1. Checkout
       ├─ 2. Lint (flake8)
       ├─ 3. IaC Validate (terraform validate)
       ├─ 4. Build & Test (Docker + pytest 88% cov)
       ├─ 5. SonarQube Analysis
       ├─ 6. Quality Gate ── FAIL → pipeline aborted
       ├─ 7. Security Scan (Trivy)
       ├─ 8. Push → ghcr.io/afif-yassine/sentiment-ai:<sha>
       ├─ 9. IaC Apply (terraform apply → sentiment-staging)
       ├─ 10. Deploy Staging (health check)
       └─ 11. Smoke Test (/health + /metrics + Prometheus + Grafana)
```

---

## 👤 Author

**Yassine Afif**
- GitHub: [@afif-yassine](https://github.com/afif-yassine)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
