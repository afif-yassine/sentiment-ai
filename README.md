# 🤖 SentimentAI

> REST API for sentiment analysis — DevOps project built with FastAPI, Docker, and Jenkins CI/CD

[![Pipeline](https://img.shields.io/badge/CI%2FCD-Jenkins-blue?logo=jenkins)](http://localhost:8080)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker)](https://github.com/afif-yassine/sentiment-ai/pkgs/container/sentiment-ai)
[![Python](https://img.shields.io/badge/Python-3.11-yellow?logo=python)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📋 Overview

SentimentAI is a REST API that receives a text input, analyzes it, and returns a sentiment label (**POSITIVE**, **NEGATIVE**, or **NEUTRAL**) with a confidence score between 0 and 1.

This project is part of a 5-part DevOps formation:

| TP | Topic | Status |
|----|-------|--------|
| TP1 | Git + Docker + Compose | ✅ Done |
| TP2 | Jenkins Pipeline (build + test + push) | ✅ Done |
| TP3 | SonarQube + Trivy (Quality & Security) | 🔄 Upcoming |
| TP4 | Terraform IaC + Docker provider | 🔄 Upcoming |
| TP5 | Monitoring with Prometheus + Grafana | 🔄 Upcoming |

---

## 🏗️ Project Structure

```
sentiment-ai/
├── src/
│   ├── __init__.py
│   ├── main.py          # FastAPI application & endpoints
│   ├── model.py         # Sentiment analysis model
│   └── schemas.py       # Pydantic data models
├── tests/
│   ├── __init__.py
│   └── test_api.py      # Unit & integration tests
├── .github/
│   └── workflows/       # GitHub Actions (future)
├── Dockerfile           # Container definition
├── docker-compose.yml   # Multi-container stack
├── Jenkinsfile          # CI/CD pipeline (4 stages)
├── Makefile             # Automation commands
├── requirements.txt     # Pinned Python dependencies
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites
- Docker Desktop
- Make (optional)

### Run with Docker Compose

```bash
docker compose up -d
```

API available at **http://localhost:8080**

### Run tests

```bash
make test
# or directly:
docker run --rm -v $(PWD):/app -w /app sentiment-ai:latest \
  pytest tests/ -v --cov=src --cov-report=term-missing
```

---

## 📡 API Endpoints

### `GET /health`
Health check endpoint used by Docker and load balancers.

```bash
curl http://localhost:8080/health
# {"status": "ok"}
```

### `POST /predict`
Analyzes the sentiment of the provided text.

**Request:**
```json
{
  "text": "Ce produit est excellent !"
}
```

**Response:**
```json
{
  "label": "POSITIVE",
  "score": 0.7,
  "text": "Ce produit est excellent !"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `label` | string | `POSITIVE`, `NEGATIVE`, or `NEUTRAL` |
| `score` | float | Confidence score between 0.0 and 1.0 |
| `text` | string | Original text (for traceability) |

---

## 🐳 Docker

### Build the image

```bash
docker build -t sentiment-ai:latest .
```

### Run the container

```bash
docker run -d --name sentiment -p 8080:8000 sentiment-ai:latest
```

### Available Makefile targets

| Command | Description |
|---------|-------------|
| `make build` | Build the Docker image |
| `make run` | Start the stack with Docker Compose |
| `make test` | Run tests inside Docker |
| `make stop` | Stop the stack |
| `make clean` | Remove containers and image |
| `make tag` | Create git tag v0.1.0 and push |

---

## ⚙️ CI/CD Pipeline (Jenkins)

The `Jenkinsfile` defines a 4-stage pipeline:

```
Checkout → Lint → Build & Test → Push
```

| Stage | Description |
|-------|-------------|
| **Checkout** | Clones the repo and displays branch/commit info |
| **Lint** | Runs flake8 on `src/` (max line length: 100) |
| **Build & Test** | Builds Docker image tagged with Git SHA, runs pytest with 70% coverage gate |
| **Push** | Pushes image to `ghcr.io` (only on `main` branch) |

Each build produces an image tagged with the short Git SHA (e.g. `sentiment-ai:a9502d0`) for full traceability.

---

## 🧪 Tests

3 tests covering the main API behavior:

```
tests/test_api.py::test_health               PASSED
tests/test_api.py::test_predict_positive     PASSED
tests/test_api.py::test_predict_empty_fails  PASSED

Coverage: 91%
```

---

## 📦 Docker Registry

Images are published to GitHub Container Registry:

```bash
docker pull ghcr.io/afif-yassine/sentiment-ai:latest
```

---

## 👤 Author

**Yassine Afif**
- GitHub: [@afif-yassine](https://github.com/afif-yassine)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
