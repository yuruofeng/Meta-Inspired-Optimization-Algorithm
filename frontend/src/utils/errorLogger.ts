/**
 * 结构化错误日志工具
 * 统一管理错误日志记录，支持存储到 localStorage
 */

export interface ErrorLogEntry {
  timestamp: string;
  type: 'error' | 'api_error' | 'warning';
  message: string;
  details?: unknown;
  stack?: string;
  url?: string;
}

const MAX_LOG_ENTRIES = 100;
const STORAGE_KEY = 'error_logs';

class ErrorLogger {
  private logs: ErrorLogEntry[] = [];

  constructor() {
    this.loadLogs();
  }

  /**
   * 从 localStorage 加载日志
   */
  private loadLogs(): void {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        this.logs = JSON.parse(stored);
      }
    } catch (e) {
      console.warn('[ErrorLogger] 无法加载日志:', e);
      this.logs = [];
    }
  }

  /**
   * 保存日志到 localStorage
   */
  private saveLogs(): void {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.logs));
    } catch (e) {
      console.warn('[ErrorLogger] 无法保存日志:', e);
    }
  }

  /**
   * 添加日志条目
   */
  private addLog(entry: ErrorLogEntry): void {
    this.logs.unshift(entry);
    // 限制日志数量
    if (this.logs.length > MAX_LOG_ENTRIES) {
      this.logs = this.logs.slice(0, MAX_LOG_ENTRIES);
    }
    this.saveLogs();
  }

  /**
   * 记录一般错误
   */
  error(message: string, error?: Error | unknown): void {
    const entry: ErrorLogEntry = {
      timestamp: new Date().toISOString(),
      type: 'error',
      message,
      url: window.location.href,
    };

    if (error instanceof Error) {
      entry.details = error.message;
      entry.stack = error.stack;
    } else if (error) {
      entry.details = error;
    }

    console.error('[ErrorLogger]', message, error || '');
    this.addLog(entry);
  }

  /**
   * 记录 API 错误
   */
  apiError(message: string, statusCode?: number, details?: unknown): void {
    const entry: ErrorLogEntry = {
      timestamp: new Date().toISOString(),
      type: 'api_error',
      message,
      details: {
        statusCode,
        details,
      },
      url: window.location.href,
    };

    console.error('[ErrorLogger] API Error:', message, { statusCode, details });
    this.addLog(entry);
  }

  /**
   * 记录警告
   */
  warn(message: string, details?: unknown): void {
    const entry: ErrorLogEntry = {
      timestamp: new Date().toISOString(),
      type: 'warning',
      message,
      details,
      url: window.location.href,
    };

    console.warn('[ErrorLogger]', message, details || '');
    this.addLog(entry);
  }

  /**
   * 获取所有日志
   */
  getLogs(): ErrorLogEntry[] {
    return [...this.logs];
  }

  /**
   * 获取最近的日志
   */
  getRecentLogs(count: number = 10): ErrorLogEntry[] {
    return this.logs.slice(0, count);
  }

  /**
   * 清除所有日志
   */
  clearLogs(): void {
    this.logs = [];
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch (e) {
      console.warn('[ErrorLogger] 无法清除日志:', e);
    }
  }

  /**
   * 导出日志为 JSON 字符串
   */
  exportLogs(): string {
    return JSON.stringify(this.logs, null, 2);
  }
}

// 导出单例
export const errorLogger = new ErrorLogger();
