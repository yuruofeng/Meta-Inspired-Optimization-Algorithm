"""Task status and WebSocket routes."""

import asyncio

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect

from app.schemas.models import CancelTaskResponse, TaskProgress
from app.services.task_manager import task_manager

router = APIRouter()


@router.get("/api/v1/tasks/{task_id}", response_model=TaskProgress, tags=["任务管理"])
async def get_task_status(task_id: str):
    """获取任务状态。"""
    task = task_manager.get_status(task_id)
    if task is None:
        raise HTTPException(status_code=404, detail=f"任务 {task_id} 不存在")
    return task


@router.delete("/api/v1/tasks/{task_id}", response_model=CancelTaskResponse, tags=["任务管理"])
async def cancel_task(task_id: str):
    """取消任务。"""
    response = task_manager.cancel(task_id)
    if response is None:
        raise HTTPException(status_code=404, detail=f"任务 {task_id} 不存在")
    return response


@router.websocket("/ws/tasks/{task_id}")
async def websocket_task_progress(websocket: WebSocket, task_id: str):
    """WebSocket 实时进度推送。"""
    await websocket.accept()

    try:
        while True:
            task = task_manager.get_status(task_id)
            if task is not None:
                await websocket.send_json({"type": "progress", "data": task.model_dump()})

                if task.status in ["completed", "error", "cancelled"]:
                    result = task_manager.get_result(task_id)
                    if result is not None:
                        await websocket.send_json({"type": "result", "data": result})
                    break

            await asyncio.sleep(0.1)
    except WebSocketDisconnect:
        print(f"WebSocket断开: {task_id}")
    except Exception as exc:
        await websocket.send_json({"type": "error", "data": str(exc)})

