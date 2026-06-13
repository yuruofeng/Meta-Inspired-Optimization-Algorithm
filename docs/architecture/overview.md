# Architecture Overview

## Summary

The platform is organized as three explicit layers:

```text
frontend/  ->  backend/  ->  matlab/api/  ->  matlab/core|algorithms|problems
```

The MATLAB layer owns optimization algorithms and algorithm metadata. The backend exposes stable HTTP and WebSocket contracts. The frontend consumes backend catalog and execution APIs, with static data kept only as fallback display data.

## MATLAB Layer

`matlab/core` defines base classes, result types, and `AlgorithmRegistry`.

`matlab/algorithms` contains concrete algorithm implementations. Each algorithm should register itself through `AlgorithmRegistry.register(...)` and expose its parameters through `PARAM_SCHEMA`.

`matlab/api` contains the stable public MATLAB entrypoints used by the backend:

- `registerAllAlgorithms`
- `apiGetMetadata`
- `apiRunOptimization`

## Backend Layer

`backend/app/main.py` only creates the FastAPI app, attaches middleware, mounts routers, and registers error handlers.

Route modules live under `backend/app/api`:

- `algorithms.py`: algorithm catalog and schema routes
- `benchmarks.py`: benchmark, robust benchmark, and MD-MTSP routes
- `optimization.py`: single, comparison, and batch optimization routes
- `tasks.py`: task status and WebSocket progress
- `health.py`: health check

Services live under `backend/app/services`:

- `matlab_bridge.py`: MATLAB Engine communication and simulation fallback
- `task_manager.py`: batch task state and task result ownership
- `problem_catalog.py`: backend-owned static application and robust benchmark catalogs

## Frontend Layer

`frontend/src/hooks/useCatalogData.ts` is the default catalog loading boundary. It loads algorithms and problems from `/api/v1/...` and falls back to local constants if the backend is unavailable.

Pages should consume catalog data through hooks or stores instead of importing large static data arrays directly. Constants remain appropriate for presentation data such as colors, labels, and fallback fixtures.

## Runtime Flow

1. The frontend requests catalog data from the backend.
2. The backend obtains algorithm metadata from `apiGetMetadata('algorithms')`.
3. `apiGetMetadata` reads registered MATLAB algorithms from `AlgorithmRegistry`.
4. Optimization requests call `apiRunOptimization` through `MatlabBridge`.
5. Batch requests are tracked by `TaskManager` and streamed through WebSocket progress messages.

