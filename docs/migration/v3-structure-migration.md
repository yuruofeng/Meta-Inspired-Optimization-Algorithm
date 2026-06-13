# v3 Structure Migration Guide

## What Changed

The repository was reorganized from a flat mixed layout into explicit MATLAB, backend, frontend, and documentation roots.

## Path Mapping

| Old path | New path |
| --- | --- |
| `core/` | `matlab/core/` |
| `algorithms/` | `matlab/algorithms/` |
| `problems/` | `matlab/problems/` |
| `shared/` | `matlab/shared/` |
| `utils/` | `matlab/utils/` |
| `api/` | `matlab/api/` |
| `examples/` | `matlab/examples/` |
| `tests/` | `matlab/tests/` |
| `api_server/` | `backend/app/` and `backend/requirements.txt` |
| `web-frontend/` | `frontend/` |

## User Commands

Before:

```bat
cd api_server
python main.py
```

After:

```bat
cd backend
python -m app.main
```

Before:

```bat
cd web-frontend
npm run dev
```

After:

```bat
cd frontend
npm run dev
```

Before:

```matlab
cd tests
run_all_tests
```

After:

```matlab
cd matlab/tests
run_all_tests
```

## Compatibility Notes

- MATLAB public function names are unchanged.
- Backend REST and WebSocket paths are unchanged.
- `backend/app/models.py` and `backend/app/matlab_bridge.py` remain as compatibility import surfaces for one transition window.
- Frontend static catalog constants still exist as fallback data, but runtime pages now prefer API-loaded catalog data.

## Verification After Migration

Run these checks after updating local dependencies:

```bat
cd backend
pytest
```

```bat
cd frontend
npm run lint
npm run test
npm run build
```

```matlab
cd matlab/tests
run_all_tests
```

The historical baseline MATLAB test suite already contained many failures before this structural migration. Treat new registry/API smoke tests separately when checking migration-specific regressions.

During the migration smoke test, `registerAllAlgorithms` registered 20 currently loadable algorithms and skipped broken algorithm classes with warnings. Those skipped classes have pre-existing MATLAB class-definition issues, such as redefining superclass properties.
