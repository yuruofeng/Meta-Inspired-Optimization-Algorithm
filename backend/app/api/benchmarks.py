"""Benchmark and application problem catalog routes."""

from fastapi import APIRouter, HTTPException

from app.schemas.models import BenchmarkFunction, MDMTSPFunction, RobustBenchmarkFunction
from app.services.matlab_bridge import matlab_bridge
from app.services.problem_catalog import MDMTSP_FUNCTIONS, ROBUST_BENCHMARK_FUNCTIONS, ROBUST_TYPE_NAMES

router = APIRouter(prefix="/api/v1")


@router.get("/benchmarks", response_model=list[BenchmarkFunction], tags=["基准函数"])
async def get_benchmarks():
    """获取所有基准函数。"""
    try:
        return await matlab_bridge.get_benchmarks()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"获取基准函数列表失败: {exc}") from exc


@router.get("/benchmarks/{benchmark_id}", response_model=BenchmarkFunction, tags=["基准函数"])
async def get_benchmark(benchmark_id: str):
    """获取单个基准函数定义。"""
    benchmarks = await matlab_bridge.get_benchmarks()
    for benchmark in benchmarks:
        if benchmark.get("id") == benchmark_id:
            return benchmark
    raise HTTPException(status_code=404, detail=f"基准函数 {benchmark_id} 不存在")


@router.get("/robust-benchmarks", response_model=list[RobustBenchmarkFunction], tags=["鲁棒基准函数"])
async def get_robust_benchmarks():
    """获取所有鲁棒基准测试函数。"""
    return ROBUST_BENCHMARK_FUNCTIONS


@router.get("/robust-benchmarks/types", tags=["鲁棒基准函数"])
async def get_robust_benchmark_types():
    """获取鲁棒基准函数类型列表。"""
    return [{"id": key, "name": value} for key, value in ROBUST_TYPE_NAMES.items()]


@router.get("/robust-benchmarks/{benchmark_id}", response_model=RobustBenchmarkFunction, tags=["鲁棒基准函数"])
async def get_robust_benchmark(benchmark_id: str):
    """获取单个鲁棒基准函数定义。"""
    for benchmark in ROBUST_BENCHMARK_FUNCTIONS:
        if benchmark.get("id") == benchmark_id:
            return benchmark
    raise HTTPException(status_code=404, detail=f"鲁棒基准函数 {benchmark_id} 不存在")


@router.get("/mdmtsp-problems", response_model=list[MDMTSPFunction], tags=["MD-MTSP问题"])
async def get_mdmtsp_problems():
    """获取所有 MD-MTSP 问题配置。"""
    return MDMTSP_FUNCTIONS


@router.get("/mdmtsp-problems/{problem_id}", response_model=MDMTSPFunction, tags=["MD-MTSP问题"])
async def get_mdmtsp_problem(problem_id: str):
    """获取单个 MD-MTSP 问题配置。"""
    for problem in MDMTSP_FUNCTIONS:
        if problem.get("id") == problem_id:
            return problem
    raise HTTPException(status_code=404, detail=f"MD-MTSP问题 {problem_id} 不存在")

