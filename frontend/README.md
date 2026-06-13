# Frontend

React + TypeScript + Vite frontend for the Metaheuristic Optimization Algorithm Platform.

## Commands

```bat
npm install
npm run dev
npm run lint
npm run test
npm run build
```

## Data Flow

Runtime catalog data is loaded through `src/hooks/useCatalogData.ts`:

1. Request algorithms and problems from the backend `/api/v1/...` routes.
2. Use local constants as fallback data when the backend is unavailable.
3. Keep colors, labels, and fixture data in `src/constants`.

The frontend should not treat static constants as the canonical algorithm source. MATLAB algorithm classes and the backend catalog API own runtime metadata.
