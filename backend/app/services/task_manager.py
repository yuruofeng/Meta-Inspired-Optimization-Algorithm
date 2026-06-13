"""Task state and batch execution service."""

import asyncio
import uuid
from typing import Dict

from app.schemas.models import BatchTaskResponse, CancelTaskResponse, ComparisonRequest, TaskProgress
from app.services.matlab_bridge import matlab_bridge


class TaskManager:
    """Owns long-running optimization task state."""

    def __init__(self) -> None:
        self.active_tasks: Dict[str, TaskProgress] = {}
        self.task_results: Dict[str, Dict] = {}

    def create_batch_task(self, request: ComparisonRequest) -> BatchTaskResponse:
        task_id = str(uuid.uuid4())
        self.active_tasks[task_id] = TaskProgress(
            taskId=task_id,
            status="idle",
            currentIteration=0,
            totalIterations=request.config.maxIterations * len(request.algorithms),
            currentFitness=float("inf"),
            bestFitness=float("inf"),
            elapsedTime=0,
            estimatedRemaining=0,
            progress=0,
        )
        asyncio.create_task(self.run_batch_task(task_id, request))
        return BatchTaskResponse(taskId=task_id)

    def get_status(self, task_id: str) -> TaskProgress | None:
        return self.active_tasks.get(task_id)

    def get_result(self, task_id: str) -> Dict | None:
        return self.task_results.get(task_id)

    def cancel(self, task_id: str) -> CancelTaskResponse | None:
        task = self.active_tasks.get(task_id)
        if task is None:
            return None
        if task.status == "running":
            task.status = "cancelled"
            return CancelTaskResponse(cancelled=True)
        return CancelTaskResponse(cancelled=False)

    async def run_batch_task(self, task_id: str, request: ComparisonRequest) -> None:
        task = self.active_tasks[task_id]
        task.status = "running"

        results = {}
        total_iterations = max(request.config.maxIterations * len(request.algorithms), 1)
        completed_iterations = 0

        for algorithm_id in request.algorithms:
            if task.status == "cancelled":
                break

            def progress_callback(current: int, total: int, fitness: float) -> None:
                nonlocal completed_iterations
                completed_iterations += 1
                task.currentIteration = completed_iterations
                task.currentFitness = fitness
                task.bestFitness = min(task.bestFitness, fitness)
                task.progress = min((completed_iterations / total_iterations) * 100, 100)

            try:
                result = await matlab_bridge.run_optimization(
                    algorithm=algorithm_id,
                    problem_id=request.problem.id,
                    config=request.config.model_dump(),
                    progress_callback=progress_callback,
                )
                results[algorithm_id] = result
            except Exception:
                task.status = "error"
                return

        if task.status != "cancelled":
            task.status = "completed"
            task.progress = 100
            task_results = {algorithm: result for algorithm, result in results.items()}
            self.task_results[task_id] = task_results


task_manager = TaskManager()

