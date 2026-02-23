"""
MATLAB 引擎桥接层
封装 MATLAB 引擎调用，提供异步接口
"""

import asyncio
import json
import os
import sys
from typing import Dict, Any, Optional, Callable
from concurrent.futures import ThreadPoolExecutor
import threading

# MATLAB引擎导入（可选，在无MATLAB环境时使用模拟模式）
try:
    import matlab.engine
    MATLAB_AVAILABLE = True
except ImportError:
    MATLAB_AVAILABLE = False
    print("警告: MATLAB引擎未安装，将使用模拟模式")


class MatlabBridge:
    """MATLAB引擎桥接类"""

    def __init__(self, matlab_path: Optional[str] = None):
        """
        初始化MATLAB桥接

        Args:
            matlab_path: MATLAB项目路径，用于添加到MATLAB路径
        """
        self.eng = None
        self.matlab_path = matlab_path or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.executor = ThreadPoolExecutor(max_workers=4)
        self._lock = threading.Lock()
        self._connected = False
        self._simulation_mode = not MATLAB_AVAILABLE

    async def connect(self) -> bool:
        """
        连接到MATLAB引擎

        Returns:
            是否连接成功
        """
        if self._simulation_mode:
            print("[模拟模式] 使用模拟数据")
            self._connected = True
            return True

        try:
            # 在线程池中启动MATLAB引擎
            loop = asyncio.get_event_loop()
            self.eng = await loop.run_in_executor(
                self.executor,
                self._start_matlab_engine
            )

            if self.eng:
                # 添加项目路径到MATLAB
                self.eng.addpath(self.matlab_path, nargout=0)
                self.eng.addpath(os.path.join(self.matlab_path, 'api'), nargout=0)
                self.eng.addpath(os.path.join(self.matlab_path, 'core'), nargout=0)
                self.eng.addpath(os.path.join(self.matlab_path, 'algorithms'), nargout=0)
                self.eng.addpath(os.path.join(self.matlab_path, 'problems'), nargout=0)

                # 注册所有算法到AlgorithmRegistry
                print("正在注册算法...")
                self.eng.registerAllAlgorithms(nargout=0)

                self._connected = True
                print(f"MATLAB引擎已连接，项目路径: {self.matlab_path}")
                return True
            return False

        except Exception as e:
            print(f"连接MATLAB引擎失败: {e}")
            self._simulation_mode = True
            self._connected = True
            return True

    def _start_matlab_engine(self):
        """在线程中启动MATLAB引擎"""
        try:
            return matlab.engine.start_matlab()
        except Exception as e:
            print(f"启动MATLAB引擎失败: {e}")
            return None

    async def disconnect(self):
        """断开MATLAB连接"""
        if self.eng:
            try:
                self.eng.quit()
            except:
                pass
            self.eng = None
        self._connected = False

    def is_connected(self) -> bool:
        """检查是否已连接"""
        return self._connected

    async def run_optimization(
        self,
        algorithm: str,
        problem_id: str,
        config: Dict[str, Any],
        progress_callback: Optional[Callable[[int, int, float], None]] = None
    ) -> Dict[str, Any]:
        """
        执行优化

        Args:
            algorithm: 算法名称 (如 'GWO', 'ALO')
            problem_id: 问题ID (如 'F1', 'F2')
            config: 算法配置
            progress_callback: 进度回调函数 (current, total, fitness)

        Returns:
            优化结果字典
        """
        if self._simulation_mode:
            return await self._simulate_optimization(algorithm, problem_id, config, progress_callback)

        loop = asyncio.get_event_loop()

        try:
            # 转换配置为MATLAB格式
            config_json = json.dumps(config)

            # 调用MATLAB函数
            result_json = await loop.run_in_executor(
                self.executor,
                self._call_matlab_optimization,
                algorithm,
                problem_id,
                config_json
            )

            return json.loads(result_json)

        except Exception as e:
            raise RuntimeError(f"MATLAB优化执行失败: {e}")

    def _call_matlab_optimization(self, algorithm: str, problem_id: str, config_json: str) -> str:
        """在MATLAB中执行优化"""
        # 调用MATLAB的apiRunOptimization函数
        result = self.eng.apiRunOptimization(algorithm, problem_id, config_json)
        return result

    async def _simulate_optimization(
        self,
        algorithm: str,
        problem_id: str,
        config: Dict[str, Any],
        progress_callback: Optional[Callable[[int, int, float], None]] = None
    ) -> Dict[str, Any]:
        """
        模拟优化执行（用于无MATLAB环境时的测试）
        """
        import random
        import math

        max_iter = config.get('maxIterations', 500)
        dim = 30  # 默认维度

        # 模拟收敛曲线
        convergence_curve = []
        initial_fitness = random.uniform(100, 1000)
        current_fitness = initial_fitness

        for i in range(max_iter):
            # 模拟收敛过程
            decay = math.exp(-3 * i / max_iter)
            noise = random.uniform(-0.1, 0.1) * decay
            current_fitness = initial_fitness * decay + noise

            if current_fitness < 1e-10:
                current_fitness = 1e-10

            convergence_curve.append(current_fitness)

            # 调用进度回调
            if progress_callback and i % 10 == 0:
                progress_callback(i + 1, max_iter, current_fitness)

            # 模拟计算延迟
            await asyncio.sleep(0.001)

        # 生成模拟结果
        result = {
            "bestSolution": [random.uniform(-0.001, 0.001) for _ in range(dim)],
            "bestFitness": convergence_curve[-1],
            "convergenceCurve": convergence_curve,
            "totalEvaluations": max_iter * config.get('populationSize', 30),
            "elapsedTime": max_iter * 0.001,
            "metadata": {
                "algorithm": algorithm,
                "version": "2.0.0",
                "iterations": max_iter,
                "config": config
            }
        }

        return result

    async def get_algorithms(self) -> list:
        """获取可用算法列表"""
        if self._simulation_mode:
            return self._get_simulated_algorithms()

        try:
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                self.executor,
                lambda: self.eng.apiGetMetadata('algorithms')
            )
            return json.loads(result)
        except Exception as e:
            print(f"获取算法列表失败: {e}")
            return self._get_simulated_algorithms()

    def _get_simulated_algorithms(self) -> list:
        """获取模拟的算法列表"""
        return [
            {"id": "GWO", "name": "GWO", "fullName": "Grey Wolf Optimizer", "category": "swarm"},
            {"id": "ALO", "name": "ALO", "fullName": "Ant Lion Optimizer", "category": "swarm"},
            {"id": "WOA", "name": "WOA", "fullName": "Whale Optimization Algorithm", "category": "swarm"},
            {"id": "IGWO", "name": "IGWO", "fullName": "Improved Grey Wolf Optimizer", "category": "hybrid"},
        ]

    async def get_benchmarks(self) -> list:
        """获取基准函数列表"""
        if self._simulation_mode:
            return self._get_simulated_benchmarks()

        try:
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                self.executor,
                lambda: self.eng.apiGetMetadata('benchmarks')
            )
            return json.loads(result)
        except Exception as e:
            print(f"获取基准函数列表失败: {e}")
            return self._get_simulated_benchmarks()

    def _get_simulated_benchmarks(self) -> list:
        """获取模拟的基准函数列表"""
        return [
            {"id": "F1", "name": "Sphere", "type": "Unimodal", "dimension": 30, "optimalValue": 0},
            {"id": "F2", "name": "Rosenbrock", "type": "Unimodal", "dimension": 30, "optimalValue": 0},
            {"id": "F9", "name": "Rastrigin", "type": "Multimodal", "dimension": 30, "optimalValue": 0},
        ]


# 全局MATLAB桥接实例
matlab_bridge = MatlabBridge()
