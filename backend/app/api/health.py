"""Health check routes."""

from fastapi import APIRouter

from app.services.matlab_bridge import matlab_bridge

router = APIRouter(tags=["系统"])


@router.get("/health")
async def health_check():
    """健康检查。"""
    return {
        "status": "healthy",
        "matlab_connected": matlab_bridge.is_connected(),
        "simulation_mode": matlab_bridge._simulation_mode,
    }

