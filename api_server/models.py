"""
Pydantic 数据模型定义
对应前端 TypeScript 类型
"""

from typing import Dict, List, Optional, Union, Literal
from pydantic import BaseModel, Field


# ==================== 基础类型 ====================

class AlgorithmConfig(BaseModel):
    """算法配置参数"""
    populationSize: int = Field(default=30, description="种群大小")
    maxIterations: int = Field(default=500, description="最大迭代次数")
    verbose: bool = Field(default=False, description="是否显示进度")
    # 允许额外参数
    class Config:
        extra = "allow"


class ParamSchema(BaseModel):
    """参数模式定义"""
    type: Literal["integer", "float", "boolean", "string"]
    default: Union[int, float, bool, str]
    min: Optional[float] = None
    max: Optional[float] = None
    description: str


class ResultMetadata(BaseModel):
    """优化结果元数据"""
    algorithm: str
    version: str
    iterations: int
    config: AlgorithmConfig
    timestamp: Optional[str] = None


class OptimizationResult(BaseModel):
    """优化结果（对应MATLAB OptimizationResult类）"""
    bestSolution: List[float]
    bestFitness: float
    convergenceCurve: List[float]
    totalEvaluations: int
    elapsedTime: float
    metadata: ResultMetadata


# ==================== 算法定义 ====================

class AlgorithmReference(BaseModel):
    """算法参考文献"""
    authors: str
    year: int
    doi: Optional[str] = None
    title: Optional[str] = None


class AlgorithmComplexity(BaseModel):
    """算法复杂度"""
    time: str
    space: str


class Algorithm(BaseModel):
    """算法定义"""
    id: str
    name: str
    fullName: str
    version: str
    description: str
    category: Literal["swarm", "evolutionary", "physics", "hybrid"]
    paramSchema: Dict[str, ParamSchema]
    reference: AlgorithmReference
    complexity: AlgorithmComplexity


# ==================== 基准函数 ====================

class BenchmarkFunction(BaseModel):
    """基准测试函数"""
    id: str
    name: str
    type: Literal["Unimodal", "Multimodal", "Fixed-dimension Multimodal"]
    dimension: int
    lowerBound: Union[float, List[float]]
    upperBound: Union[float, List[float]]
    optimalValue: float
    description: Optional[str] = None


# ==================== 请求/响应模型 ====================

class ProblemDefinition(BaseModel):
    """问题定义"""
    id: str
    type: Literal["benchmark", "custom"] = "benchmark"
    dimension: int
    lowerBound: Union[float, List[float]]
    upperBound: Union[float, List[float]]


class OptimizationRequest(BaseModel):
    """单次优化请求"""
    algorithm: str
    problem: ProblemDefinition
    config: AlgorithmConfig


class ComparisonRequest(BaseModel):
    """算法对比请求"""
    algorithms: List[str]
    problem: ProblemDefinition
    config: AlgorithmConfig
    runsPerAlgorithm: int = Field(default=1, ge=1, le=100)


class ComparisonStatistics(BaseModel):
    """对比统计"""
    meanFitness: Dict[str, float]
    stdFitness: Dict[str, float]
    meanTime: Dict[str, float]
    rankings: Dict[str, int]


class ComparisonResult(BaseModel):
    """算法对比结果"""
    algorithms: List[str]
    functionName: str
    results: Dict[str, OptimizationResult]
    statistics: ComparisonStatistics


# ==================== 任务进度 ====================

class TaskProgress(BaseModel):
    """任务进度"""
    taskId: str
    status: Literal["idle", "running", "completed", "error", "cancelled"]
    currentIteration: int
    totalIterations: int
    currentFitness: float
    bestFitness: float
    elapsedTime: float
    estimatedRemaining: float
    progress: float = Field(ge=0, le=100, description="进度百分比 0-100")


# ==================== API响应 ====================

class BatchTaskResponse(BaseModel):
    """批量任务响应"""
    taskId: str


class CancelTaskResponse(BaseModel):
    """取消任务响应"""
    cancelled: bool


class ApiError(BaseModel):
    """API错误响应"""
    code: str
    message: str
    details: Optional[str] = None
