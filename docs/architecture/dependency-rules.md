# Dependency Rules

## Allowed Direction

Dependencies must flow in one direction:

```text
frontend -> backend -> matlab/api -> matlab/core|algorithms|problems
```

Lower layers must not import or depend on higher layers.

## Rules By Layer

- `frontend` may call backend HTTP/WebSocket APIs and may use local fallback constants.
- `backend` may call MATLAB public API functions through `MatlabBridge`.
- `matlab/api` may use `matlab/core`, `matlab/algorithms`, and `matlab/problems`.
- `matlab/algorithms` may depend on `matlab/core` and `matlab/shared`.
- `matlab/core` must not depend on individual algorithm implementations.

## Metadata Ownership

Algorithm metadata is owned by MATLAB classes and `AlgorithmRegistry`.

Allowed:

- Algorithm classes define `PARAM_SCHEMA`.
- Algorithm classes call `AlgorithmRegistry.register(...)`.
- Backend reads algorithm metadata through `apiGetMetadata('algorithms')`.
- Frontend reads algorithm metadata through `/api/v1/algorithms`.

Avoid:

- Hand-maintaining independent algorithm lists in Python.
- Treating frontend constants as the canonical algorithm catalog.
- Adding backend routes that import frontend data.

## Communication Boundaries

- REST paths remain versioned under `/api/v1`.
- Task progress remains under `/ws/tasks/{task_id}`.
- MATLAB public API names remain stable even if files move under `matlab/api`.

