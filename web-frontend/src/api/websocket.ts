/**
 * WebSocket 连接管理
 * 用于实时获取优化进度
 */

import type { TaskProgress, OptimizationResult, WebSocketMessage } from '../types';

type ProgressHandler = (progress: TaskProgress) => void;
type ResultHandler = (result: OptimizationResult) => void;
type ErrorHandler = (error: Error) => void;

const WS_BASE_URL = import.meta.env.VITE_WS_BASE_URL || 'ws://localhost:8000';

export class OptimizationWebSocket {
  private ws: WebSocket | null = null;
  private taskId: string;
  private onProgress: ProgressHandler;
  private onResult: ResultHandler;
  private onError: ErrorHandler;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 2000;
  private isConnecting = false;

  constructor(
    taskId: string,
    handlers: {
      onProgress: ProgressHandler;
      onResult: ResultHandler;
      onError: ErrorHandler;
    }
  ) {
    this.taskId = taskId;
    this.onProgress = handlers.onProgress;
    this.onResult = handlers.onResult;
    this.onError = handlers.onError;
  }

  /**
   * 建立 WebSocket 连接
   */
  connect(): void {
    if (this.isConnecting || (this.ws && this.ws.readyState === WebSocket.OPEN)) {
      return;
    }

    this.isConnecting = true;
    const wsUrl = `${WS_BASE_URL}/ws/tasks/${this.taskId}`;

    try {
      this.ws = new WebSocket(wsUrl);

      this.ws.onopen = () => {
        console.log(`[WebSocket] 已连接任务 ${this.taskId}`);
        this.reconnectAttempts = 0;
        this.isConnecting = false;
      };

      this.ws.onmessage = (event) => {
        try {
          const message: WebSocketMessage = JSON.parse(event.data);
          this.handleMessage(message);
        } catch (e) {
          console.error('[WebSocket] 解析消息失败:', e);
        }
      };

      this.ws.onerror = (error) => {
        console.error('[WebSocket] 连接错误:', error);
        this.isConnecting = false;
        this.onError(new Error('WebSocket 连接错误'));
      };

      this.ws.onclose = () => {
        console.log('[WebSocket] 连接关闭');
        this.isConnecting = false;
        this.attemptReconnect();
      };
    } catch (error) {
      this.isConnecting = false;
      this.onError(error instanceof Error ? error : new Error('连接失败'));
    }
  }

  /**
   * 处理接收到的消息
   */
  private handleMessage(message: WebSocketMessage): void {
    switch (message.type) {
      case 'progress':
        this.onProgress(message.data as TaskProgress);
        break;
      case 'result':
        this.onResult(message.data as OptimizationResult);
        break;
      case 'error':
        this.onError(new Error(message.data as string));
        break;
      case 'connected':
        console.log('[WebSocket] 服务器确认连接');
        break;
    }
  }

  /**
   * 尝试重连
   */
  private attemptReconnect(): void {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      const delay = this.reconnectDelay * this.reconnectAttempts;
      console.log(`[WebSocket] 尝试重连 (${this.reconnectAttempts}/${this.maxReconnectAttempts})，${delay}ms后...`);

      setTimeout(() => {
        this.connect();
      }, delay);
    } else {
      this.onError(new Error('WebSocket 重连失败，已达到最大尝试次数'));
    }
  }

  /**
   * 断开连接
   */
  disconnect(): void {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
    this.reconnectAttempts = this.maxReconnectAttempts; // 阻止重连
  }

  /**
   * 获取连接状态
   */
  getReadyState(): number {
    return this.ws?.readyState ?? WebSocket.CLOSED;
  }

  /**
   * 是否已连接
   */
  isConnected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN;
  }
}
