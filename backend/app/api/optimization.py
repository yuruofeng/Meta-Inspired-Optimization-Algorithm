"""Optimization execution routes."""

from fastapi import APIRouter, HTTPException

from app.schemas.models import (
    BatchTaskResponse,
    ComparisonRequest,
    ComparisonResult,
    ComparisonStatistics,
    OptimizationRequest,
    OptimizationResult,
)
from app.services.matlab_bridge import matlab_bridge
from app.services.task_manager import task_manager

router = APIRouter(prefix="/api/v1", tags=["优化执行"])


@router.post("/optimize/single", response_model=OptimizationResult)
async def run_single_optimization(request: OptimizationRequest):
    """执行单次优化。"""
    try:
        return await matlab_bridge.run_optimization(
            algorithm=request.algorithm,
            problem_id=request.problem.id,
            config=request.config.model_dump(),
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"优化执行失败: {exc}") from exc


@router.post("/optimize/compare", response_model=ComparisonResult)
async def run_comparison(request: ComparisonRequest):
    """执行算法对比。"""
    try:
        results = {}
        times = {}

        for algorithm_id in request.algorithms:
            result = await matlab_bridge.run_optimization(
                algorithm=algorithm_id,
                problem_id=request.problem.id,
                config=request.config.model_dump(),
            )
            results[algorithm_id] = result
            times[algorithm_id] = result.get("elapsedTime", 0)

        fitness_values = {
            algorithm: result.get("bestFitness", float("inf"))
            for algorithm, result in results.items()
        }
        statistics = ComparisonStatistics(
            meanFitness=fitness_values,
            stdFitness={algorithm: 0 for algorithm in results},
            meanTime=times,
            rankings=_calculate_rankings(results),
        )

        return ComparisonResult(
            algorithms=request.algorithms,
            functionName=request.problem.id,
            results=results,
            statistics=statistics,
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"对比执行失败: {exc}") from exc


@router.post("/optimize/batch", response_model=BatchTaskResponse)
async def submit_batch_task(request: ComparisonRequest):
    """提交批量优化任务。"""
    return task_manager.create_batch_task(request)


def _calculate_rankings(results: dict[str, dict]) -> dict[str, int]:
    """按最小 bestFitness 排序计算名次。"""
    sorted_algorithms = sorted(results.items(), key=lambda item: item[1]["bestFitness"])
    return {algorithm: rank + 1 for rank, (algorithm, _) in enumerate(sorted_algorithms)}

