# Code Style

## MATLAB

- Class files use `UpperCamelCase.m`.
- Methods and local variables use `lowerCamelCase`.
- Constants use `UPPER_SNAKE_CASE` when they represent fixed values.
- Algorithm classes inherit from `BaseAlgorithm` or `MOBaseAlgorithm`.
- Algorithm parameter metadata should be exposed through `PARAM_SCHEMA`.
- Algorithm registration should call one of:
  - `AlgorithmRegistry.register('ID', 'version', @ClassName)`
  - `AlgorithmRegistry.register('ID', @ClassName)` for legacy default-version code
- MATLAB API entrypoints should remain thin protocol adapters.

## Python Backend

- Keep route handlers in `backend/app/api`.
- Keep Pydantic models in `backend/app/schemas`.
- Keep stateful or external-system logic in `backend/app/services`.
- Prefer explicit imports from `app.<module>` packages.
- Use Black-compatible formatting and type hints for public service methods.
- Route handlers should translate service exceptions into HTTP errors; services should not import FastAPI response objects.

## TypeScript Frontend

- Page components should consume catalog data through hooks or stores.
- Large static constants should be fallback fixtures or presentation maps only.
- API functions live in `frontend/src/api`.
- Shared types live in `frontend/src/types`.
- Components should not hard-code backend URLs; use the API client.

## Documentation

- Architecture decisions belong under `docs/architecture`.
- Migration notes belong under `docs/migration`.
- Style and contribution rules belong under `docs/standards`.
- README should stay short and link to detailed docs.

