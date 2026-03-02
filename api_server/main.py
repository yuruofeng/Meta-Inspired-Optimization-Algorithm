"""
FastAPI 主应用
元启发式算法优化平台后端API
"""

import asyncio
import json
import uuid
from typing import Dict, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from models import (
    OptimizationRequest,
    OptimizationResult,
    ComparisonRequest,
    ComparisonResult,
    TaskProgress,
    Algorithm,
    BenchmarkFunction,
    RobustBenchmarkFunction,
    BatchTaskResponse,
    CancelTaskResponse,
    ApiError,
    ComparisonStatistics,
)
from matlab_bridge import matlab_bridge

# ==================== 生命周期管理 ====================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时连接MATLAB
    print("正在连接MATLAB引擎...")
    await matlab_bridge.connect()
    print("MATLAB引擎连接完成")

    yield

    # 关闭时断开MATLAB
    print("正在断开MATLAB连接...")
    await matlab_bridge.disconnect()
    print("MATLAB连接已断开")


# ==================== FastAPI应用 ====================

app = FastAPI(
    title="元启发式算法优化API",
    description="提供元启发式优化算法的REST API接口",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== 任务管理 ====================

# 存储活跃的任务
active_tasks: Dict[str, TaskProgress] = {}
task_results: Dict[str, Dict] = {}


# ==================== 算法管理API ====================

@app.get("/api/v1/algorithms", response_model=list[Algorithm], tags=["算法管理"])
async def get_algorithms():
    """获取所有可用算法列表"""
    try:
        algorithms = await matlab_bridge.get_algorithms()
        return algorithms
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取算法列表失败: {e}")


@app.get("/api/v1/algorithms/{algorithm_id}", response_model=Algorithm, tags=["算法管理"])
async def get_algorithm(algorithm_id: str):
    """获取单个算法定义"""
    algorithms = await matlab_bridge.get_algorithms()
    for alg in algorithms:
        if alg.get("id") == algorithm_id:
            return alg
    raise HTTPException(status_code=404, detail=f"算法 {algorithm_id} 不存在")


@app.get("/api/v1/algorithms/{algorithm_id}/schema", tags=["算法管理"])
async def get_algorithm_schema(algorithm_id: str):
    """获取算法参数模式"""
    algorithms = await matlab_bridge.get_algorithms()
    for alg in algorithms:
        if alg.get("id") == algorithm_id:
            return alg.get("paramSchema", {})
    raise HTTPException(status_code=404, detail=f"算法 {algorithm_id} 不存在")


# ==================== 基准函数API ====================

@app.get("/api/v1/benchmarks", response_model=list[BenchmarkFunction], tags=["基准函数"])
async def get_benchmarks():
    """获取所有基准测试函数"""
    try:
        benchmarks = await matlab_bridge.get_benchmarks()
        return benchmarks
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取基准函数列表失败: {e}")


@app.get("/api/v1/benchmarks/{benchmark_id}", response_model=BenchmarkFunction, tags=["基准函数"])
async def get_benchmark(benchmark_id: str):
    """获取单个基准函数定义"""
    benchmarks = await matlab_bridge.get_benchmarks()
    for bm in benchmarks:
        if bm.get("id") == benchmark_id:
            return bm
    raise HTTPException(status_code=404, detail=f"基准函数 {benchmark_id} 不存在")


# ==================== 鲁棒基准函数API ====================

ROBUST_BENCHMARK_FUNCTIONS = [
    {"id": "R1", "name": "TP_Biased1", "type": "Biased", "dimension": 2, "lowerBound": -100, "upperBound": 100, "delta": 1, "description": "偏置测试问题1 - 搜索空间存在偏置，最优解不在中心"},
    {"id": "R2", "name": "TP_Biased2", "type": "Biased", "dimension": 2, "lowerBound": -100, "upperBound": 100, "delta": 1, "description": "偏置测试问题2 - 多个偏置区域，增加搜索难度"},
    {"id": "R3", "name": "TP_Deceptive1", "type": "Deceptive", "dimension": 2, "lowerBound": 0, "upperBound": 1, "delta": 0.01, "description": "欺骗测试问题1 - 多个局部最优陷阱，容易误导算法"},
    {"id": "R4", "name": "TP_Deceptive2", "type": "Deceptive", "dimension": 2, "lowerBound": 0, "upperBound": 1, "delta": 0.01, "description": "欺骗测试问题2 - 密集的局部最优分布"},
    {"id": "R5", "name": "TP_Deceptive3", "type": "Deceptive", "dimension": 2, "lowerBound": 0, "upperBound": 2, "delta": 0.01, "description": "欺骗测试问题3 - 四个象限有不同的欺骗结构"},
    {"id": "R6", "name": "TP_Multimodal1", "type": "Multimodal", "dimension": 2, "lowerBound": 0, "upperBound": 1, "delta": 0.01, "description": "多模态测试问题1 - 大量局部最优，测试全局搜索能力"},
    {"id": "R7", "name": "TP_Multimodal2", "type": "Multimodal", "dimension": 2, "lowerBound": 0, "upperBound": 1, "delta": 0.01, "description": "多模态测试问题2 - 对称的多模态结构"},
    {"id": "R8", "name": "TP_Flat", "type": "Flat", "dimension": 2, "lowerBound": 0, "upperBound": 1, "delta": 0.01, "description": "平坦区域测试问题 - 大面积平坦区域，梯度信息稀少"},
]

ROBUST_TYPE_NAMES = {
    "Biased": "偏置函数",
    "Deceptive": "欺骗函数",
    "Multimodal": "多模态函数",
    "Flat": "平坦函数",
}


@app.get("/api/v1/robust-benchmarks", response_model=list[RobustBenchmarkFunction], tags=["鲁棒基准函数"])
async def get_robust_benchmarks():
    """获取所有鲁棒基准测试函数"""
    return ROBUST_BENCHMARK_FUNCTIONS


@app.get("/api/v1/robust-benchmarks/types", tags=["鲁棒基准函数"])
async def get_robust_benchmark_types():
    """获取鲁棒基准函数类型列表"""
    return [{"id": k, "name": v} for k, v in ROBUST_TYPE_NAMES.items()]


@app.get("/api/v1/robust-benchmarks/{benchmark_id}", response_model=RobustBenchmarkFunction, tags=["鲁棒基准函数"])
async def get_robust_benchmark(benchmark_id: str):
    """获取单个鲁棒基准函数定义"""
    for bm in ROBUST_BENCHMARK_FUNCTIONS:
        if bm.get("id") == benchmark_id:
            return bm
    raise HTTPException(status_code=404, detail=f"鲁棒基准函数 {benchmark_id} 不存在")


# ==================== 优化执行API ====================

@app.post("/api/v1/optimize/single", response_model=OptimizationResult, tags=["优化执行"])
async def run_single_optimization(request: OptimizationRequest):
    """执行单次优化"""
    try:
        result = await matlab_bridge.run_optimization(
            algorithm=request.algorithm,
            problem_id=request.problem.id,
            config=request.config.model_dump()
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"优化执行失败: {e}")


@app.post("/api/v1/optimize/compare", response_model=ComparisonResult, tags=["优化执行"])
async def run_comparison(request: ComparisonRequest):
    """执行算法对比"""
    try:
        results = {}
        times = {}

        for algorithm_id in request.algorithms:
            result = await matlab_bridge.run_optimization(
                algorithm=algorithm_id,
                problem_id=request.problem.id,
                config=request.config.model_dump()
            )
            results[algorithm_id] = result
            times[algorithm_id] = result.get("elapsedTime", 0)

        # 计算统计数据
        statistics = ComparisonStatistics(
            meanFitness={k: v["bestFitness"] for k, v in results.items()},
            stdFitness={k: 0.0 for k in results.keys()},  # 单次运行无标准差
            meanTime=times,
            rankings=_calculate_rankings(results)
        )

        return ComparisonResult(
            algorithms=request.algorithms,
            functionName=request.problem.id,
            results=results,
            statistics=statistics
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"对比执行失败: {e}")


@app.post("/api/v1/optimize/batch", response_model=BatchTaskResponse, tags=["优化执行"])
async def submit_batch_task(request: ComparisonRequest):
    """提交批量优化任务"""
    task_id = str(uuid.uuid4())

    # 初始化任务进度
    active_tasks[task_id] = TaskProgress(
        taskId=task_id,
        status="idle",
        currentIteration=0,
        totalIterations=request.config.maxIterations * len(request.algorithms),
        currentFitness=float('inf'),
        bestFitness=float('inf'),
        elapsedTime=0,
        estimatedRemaining=0,
        progress=0
    )

    # 在后台执行任务
    asyncio.create_task(_run_batch_task(task_id, request))

    return BatchTaskResponse(taskId=task_id)


# ==================== 任务管理API ====================

@app.get("/api/v1/tasks/{task_id}", response_model=TaskProgress, tags=["任务管理"])
async def get_task_status(task_id: str):
    """获取任务状态"""
    if task_id not in active_tasks:
        raise HTTPException(status_code=404, detail=f"任务 {task_id} 不存在")
    return active_tasks[task_id]


@app.delete("/api/v1/tasks/{task_id}", response_model=CancelTaskResponse, tags=["任务管理"])
async def cancel_task(task_id: str):
    """取消任务"""
    if task_id not in active_tasks:
        raise HTTPException(status_code=404, detail=f"任务 {task_id} 不存在")

    task = active_tasks[task_id]
    if task.status == "running":
        task.status = "cancelled"
        return CancelTaskResponse(cancelled=True)
    return CancelTaskResponse(cancelled=False)


# ==================== WebSocket ====================

@app.websocket("/ws/tasks/{task_id}")
async def websocket_task_progress(websocket: WebSocket, task_id: str):
    """WebSocket实时进度推送"""
    await websocket.accept()

    try:
        while True:
            if task_id in active_tasks:
                task = active_tasks[task_id]
                await websocket.send_json({
                    "type": "progress",
                    "data": task.model_dump()
                })

                if task.status in ["completed", "error", "cancelled"]:
                    # 任务完成，发送结果后关闭
                    if task_id in task_results:
                        await websocket.send_json({
                            "type": "result",
                            "data": task_results[task_id]
                        })
                    break

            await asyncio.sleep(0.1)

    except WebSocketDisconnect:
        print(f"WebSocket断开: {task_id}")
    except Exception as e:
        await websocket.send_json({
            "type": "error",
            "data": str(e)
        })


# ==================== 辅助函数 ====================

def _calculate_rankings(results: Dict[str, Dict]) -> Dict[str, int]:
    """计算算法排名"""
    sorted_algs = sorted(
        results.items(),
        key=lambda x: x[1]["bestFitness"]
    )
    return {alg: rank + 1 for rank, (alg, _) in enumerate(sorted_algs)}


async def _run_batch_task(task_id: str, request: ComparisonRequest):
    """执行批量任务"""
    task = active_tasks[task_id]
    task.status = "running"

    results = {}
    total_iterations = request.config.maxIterations * len(request.algorithms)
    completed_iterations = 0

    for algorithm_id in request.algorithms:
        if task.status == "cancelled":
            break

        def progress_callback(current, total, fitness):
            nonlocal completed_iterations
            completed_iterations += 1
            task.currentIteration = completed_iterations
            task.currentFitness = fitness
            task.bestFitness = min(task.bestFitness, fitness)
            task.progress = (completed_iterations / total_iterations) * 100

        try:
            result = await matlab_bridge.run_optimization(
                algorithm=algorithm_id,
                problem_id=request.problem.id,
                config=request.config.model_dump(),
                progress_callback=progress_callback
            )
            results[algorithm_id] = result
        except Exception as e:
            task.status = "error"
            return

    if task.status != "cancelled":
        task.status = "completed"
        task.progress = 100
        task_results[task_id] = results


# ==================== 错误处理 ====================

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content=ApiError(
            code=f"HTTP_{exc.status_code}",
            message=str(exc.detail)
        ).model_dump()
    )


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content=ApiError(
            code="INTERNAL_ERROR",
            message="服务器内部错误",
            details=str(exc)
        ).model_dump()
    )


# ==================== 健康检查 ====================

@app.get("/health", tags=["系统"])
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "matlab_connected": matlab_bridge.is_connected(),
        "simulation_mode": matlab_bridge._simulation_mode
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
