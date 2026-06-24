terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Le provider lit DOCKER_HOST depuis l'environnement.
# - En local Windows  : npipe:////./pipe/docker_engine
# - Dans Jenkins (Linux) : unix:///var/run/docker.sock
# Laisser host vide force le provider a lire DOCKER_HOST automatiquement.
provider "docker" {
  host = var.docker_host
}

# Reseau Docker partage Jenkins / SonarQube / SentimentAI
# Ce reseau existe deja depuis le TP2/TP3 -- on l'importe
resource "docker_network" "cicd" {
  name = "cicd-network"
}

# Image Docker SentimentAI -- image LOCALE buildee par Jenkins
resource "docker_image" "sentiment" {
  name         = "sentiment-ai:${var.image_tag}"
  keep_locally = true
}

# Conteneur staging
resource "docker_container" "sentiment_staging" {
  name    = var.container_name
  image   = docker_image.sentiment.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.cicd.name
  }

  ports {
    internal = 8000
    external = var.app_port
  }

  env = [
    "ENV=staging",
    "LOG_LEVEL=INFO",
  ]

  healthcheck {
    test     = ["CMD", "curl", "-f", "http://localhost:8000/health"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }
}
