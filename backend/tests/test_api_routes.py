from fastapi.testclient import TestClient

from app.main import create_app
from app.services.matlab_bridge import matlab_bridge


def make_client() -> TestClient:
    matlab_bridge._simulation_mode = True
    matlab_bridge._connected = True
    return TestClient(create_app())


def test_health_reports_simulation_mode():
    client = make_client()

    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["simulation_mode"] is True


def test_catalog_routes_return_schema_compatible_items():
    client = make_client()

    algorithms = client.get("/api/v1/algorithms")
    benchmarks = client.get("/api/v1/benchmarks")

    assert algorithms.status_code == 200
    algorithm_payload = algorithms.json()
    algorithm_ids = {algorithm["id"] for algorithm in algorithm_payload}
    assert len(algorithm_payload) == 54
    assert {
        "GWO",
        "GA",
        "MOEAD",
        "NSGAIII",
        "WOASA",
        "PSO",
        "ACO",
        "TLBO",
        "JAYA",
        "BA",
        "FPA",
        "HS",
        "BFO",
    } <= algorithm_ids
    assert algorithm_payload[0]["paramSchema"]["populationSize"]["type"] == "integer"
    assert benchmarks.status_code == 200
    assert "lowerBound" in benchmarks.json()[0]


def test_single_optimization_route_returns_result():
    client = make_client()

    response = client.post(
        "/api/v1/optimize/single",
        json={
            "algorithm": "GWO",
            "problem": {
                "id": "F1",
                "type": "benchmark",
                "dimension": 30,
                "lowerBound": -100,
                "upperBound": 100,
            },
            "config": {"populationSize": 5, "maxIterations": 2, "verbose": False},
        },
    )

    assert response.status_code == 200
    assert response.json()["metadata"]["algorithm"] == "GWO"


def test_batch_route_creates_task():
    client = make_client()

    response = client.post(
        "/api/v1/optimize/batch",
        json={
            "algorithms": ["GWO", "ALO"],
            "problem": {
                "id": "F1",
                "type": "benchmark",
                "dimension": 30,
                "lowerBound": -100,
                "upperBound": 100,
            },
            "config": {"populationSize": 5, "maxIterations": 2, "verbose": False},
            "runsPerAlgorithm": 1,
        },
    )

    assert response.status_code == 200
    assert response.json()["taskId"]
