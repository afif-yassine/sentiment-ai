FROM python:3.11-slim

# Definir le repertoire de travail dans le conteneur
WORKDIR /app

# Etape 1 : copier UNIQUEMENT le fichier de dependances
# Cette couche sera mise en cache tant que requirements.txt ne change pas
COPY requirements.txt .

# Etape 2 : installer les dependances (couche mise en cache)
RUN pip install --no-cache-dir -r requirements.txt

# Etape 3 : copier le code source (invalide a chaque modification du code)
COPY src/ ./src/
COPY tests/ ./tests/

# Documenter le port utilise par l'application
EXPOSE 8000

# Commande de demarrage du serveur Uvicorn
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
