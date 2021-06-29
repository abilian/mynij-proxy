from starlette.testclient import TestClient

from mynij_proxy import app


def test_app():
    client = TestClient(app)
    response = client.get("/ping")
    assert response.status_code == 200
