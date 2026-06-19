from fastapi.testclient import TestClient
from src.main import app

client = TestClient(app)


def test_health():
    """Verifie que l'endpoint /health repond avec status 200."""
    r = client.get("/health")
    assert r.status_code == 200


def test_predict_positive():
    """Verifie qu'une prediction retourne la bonne structure de reponse."""
    r = client.post("/predict", json={"text": "Ce produit est excellent !"})
    assert r.status_code == 200
    data = r.json()
    # Le label doit etre l'une des 3 valeurs attendues
    assert data["label"] in ["POSITIVE", "NEGATIVE", "NEUTRAL"]
    # Le score doit etre un nombre entre 0 et 1
    assert 0 <= data["score"] <= 1


def test_predict_empty_fails():
    """Verifie que Pydantic rejette un texte vide avec une erreur 422."""
    r = client.post("/predict", json={"text": ""})
    assert r.status_code == 422
