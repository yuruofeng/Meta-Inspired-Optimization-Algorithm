# Metaheuristic Optimization Algorithm Platform

一个 MATLAB 算法内核、FastAPI 后端和 React 前端组成的元启发式优化算法平台。仓库采用三层结构组织，算法事实源以 MATLAB 类与 `AlgorithmRegistry` 为准，后端负责协议适配，前端负责交互与可视化。

## Architecture

```text
frontend/  ->  backend/  ->  matlab/api/  ->  matlab/core|algorithms|problems
React          FastAPI       MATLAB API       optimization engine
```

关键约束：

- REST API 路径保持 `/api/v1/...`。
- WebSocket 路径保持 `/ws/tasks/{task_id}`。
- MATLAB 公开入口保持 `apiRunOptimization`, `apiGetMetadata`, `registerAllAlgorithms`。
- 算法参数 schema 和注册信息以 MATLAB 算法类为准。

## Directory Layout

```text
.
├── matlab/
│   ├── api/          # MATLAB public API functions
│   ├── core/         # base classes, result objects, registry
│   ├── algorithms/   # single-objective and multi-objective algorithms
│   ├── problems/     # benchmark and application problem definitions
│   ├── shared/       # reusable operators, templates, utilities
│   ├── utils/        # MATLAB utility functions
│   ├── examples/     # MATLAB demos
│   └── tests/        # MATLAB unit tests
├── backend/
│   ├── app/api/      # FastAPI routers
│   ├── app/schemas/  # Pydantic request/response models
│   ├── app/services/ # MATLAB bridge, task manager, catalogs
│   └── tests/        # backend smoke tests
├── frontend/
│   └── src/          # React application
├── docs/
│   ├── architecture/
│   ├── migration/
│   └── standards/
└── scripts/          # Windows start/stop helpers
```

## Quick Start

Windows:

```bat
scripts\start.bat
```

Manual backend:

```bat
cd backend
pip install -r requirements.txt
python -m app.main
```

Manual frontend:

```bat
cd frontend
npm install
npm run dev
```

## Verification

MATLAB:

```matlab
cd matlab/tests
run_all_tests
```

Backend:

```bat
cd backend
pytest
```

Frontend:

```bat
cd frontend
npm run lint
npm run test
npm run build
```

## Documentation

- [Architecture Overview](docs/architecture/overview.md)
- [Dependency Rules](docs/architecture/dependency-rules.md)
- [Code Style](docs/standards/code-style.md)
- [v3 Structure Migration Guide](docs/migration/v3-structure-migration.md)

`metaheuristic_spec.md` is retained as the historical algorithm engineering standard. New architecture and migration decisions should be recorded under `docs/`.
