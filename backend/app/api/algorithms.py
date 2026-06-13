"""Algorithm catalog routes."""

from fastapi import APIRouter, HTTPException

from app.schemas.models import Algorithm
from app.services.matlab_bridge import matlab_bridge

router = APIRouter(prefix="/api/v1", tags=["算法管理"])


@router.get("/algorithms", response_model=list[Algorithm])
async def get_algorithms():
    """获取所有可用算法列表。"""
    try:
        return await matlab_bridge.get_algorithms()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"获取算法列表失败: {exc}") from exc


@router.get("/algorithms/{algorithm_id}", response_model=Algorithm)
async def get_algorithm(algorithm_id: str):
    """获取单个算法定义。"""
    algorithms = await matlab_bridge.get_algorithms()
    for algorithm in algorithms:
        if algorithm.get("id") == algorithm_id:
            return algorithm
    raise HTTPException(status_code=404, detail=f"算法 {algorithm_id} 不存在")


@router.get("/algorithms/{algorithm_id}/schema")
async def get_algorithm_schema(algorithm_id: str):
    """获取算法参数模式。"""
    algorithms = await matlab_bridge.get_algorithms()
    for algorithm in algorithms:
        if algorithm.get("id") == algorithm_id:
            return algorithm.get("paramSchema", {})
    raise HTTPException(status_code=404, detail=f"算法 {algorithm_id} 不存在")

