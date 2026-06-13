"""FastAPI application entrypoint."""

from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api import algorithms, benchmarks, health, optimization, tasks
from app.schemas.models import ApiError
from app.services.matlab_bridge import matlab_bridge


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Connect and disconnect the MATLAB bridge with the API lifecycle."""
    print("正在连接MATLAB引擎...")
    await matlab_bridge.connect()
    print("MATLAB引擎连接完成")

    yield

    print("正在断开MATLAB连接...")
    await matlab_bridge.disconnect()
    print("MATLAB连接已断开")


def create_app() -> FastAPI:
    """Create the FastAPI application and mount all routes."""
    app = FastAPI(
        title="元启发式算法优化API",
        description="提供元启发式优化算法的REST API接口",
        version="1.0.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(algorithms.router)
    app.include_router(benchmarks.router)
    app.include_router(optimization.router)
    app.include_router(tasks.router)
    app.include_router(health.router)

    register_exception_handlers(app)
    return app


def register_exception_handlers(app: FastAPI) -> None:
    """Register unified API error responses."""

    @app.exception_handler(HTTPException)
    async def http_exception_handler(request, exc):
        return JSONResponse(
            status_code=exc.status_code,
            content=ApiError(
                code=f"HTTP_{exc.status_code}",
                message=str(exc.detail),
            ).model_dump(),
        )

    @app.exception_handler(Exception)
    async def general_exception_handler(request, exc):
        return JSONResponse(
            status_code=500,
            content=ApiError(
                code="INTERNAL_ERROR",
                message="服务器内部错误",
                details=str(exc),
            ).model_dump(),
        )


app = create_app()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=False)
