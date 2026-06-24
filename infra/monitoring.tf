# Prometheus et Grafana sont geres par monitoring/docker-compose.yml (TP5).
# Ce fichier garde uniquement les references aux images pour que Terraform
# puisse les pull sans gerer le cycle de vie des conteneurs.
#
# Les conteneurs sont lances une seule fois via :
#   cd monitoring && docker compose up -d
# et ne sont PAS recreees a chaque pipeline Jenkins.

resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = true
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = true
}
