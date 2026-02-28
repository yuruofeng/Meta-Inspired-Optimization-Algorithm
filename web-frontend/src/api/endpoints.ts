/**
 * API 端点定义
 */

import { apiClient } from './client';
import type {
  Algorithm,
  BenchmarkFunction,
  OptimizationRequest,
  OptimizationResult,
  ComparisonRequest,
  ComparisonResult,
  TaskProgress,
  ExportFormat,
} from '../types';

// ==================== 算法管理 ====================

/**
 * 获取所有可用算法
 */
export async function getAlgorithms(): Promise<Algorithm[]> {
  return apiClient.get<Algorithm[]>('/api/v1/algorithms');
}

/**
 * 获取单个算法定义
 */
export async function getAlgorithm(id: string): Promise<Algorithm> {
  return apiClient.get<Algorithm>(`/api/v1/algorithms/${id}`);
}

/**
 * 获取算法参数模式
 */
export async function getAlgorithmSchema(id: string): Promise<Record<string, unknown>> {
  return apiClient.get(`/api/v1/algorithms/${id}/schema`);
}

// ==================== 基准函数 ====================

/**
 * 获取所有基准函数
 */
export async function getBenchmarks(): Promise<BenchmarkFunction[]> {
  return apiClient.get<BenchmarkFunction[]>('/api/v1/benchmarks');
}

/**
 * 获取单个基准函数
 */
export async function getBenchmark(id: string): Promise<BenchmarkFunction> {
  return apiClient.get<BenchmarkFunction>(`/api/v1/benchmarks/${id}`);
}

// ==================== 优化执行 ====================

/**
 * 执行单次优化
 */
export async function runOptimization(request: OptimizationRequest, signal?: AbortSignal): Promise<OptimizationResult> {
  return apiClient.post<OptimizationResult>('/api/v1/optimize/single', request, signal ? { signal } : undefined);
}

/**
 * 执行算法对比
 */
export async function runComparison(request: ComparisonRequest, signal?: AbortSignal): Promise<ComparisonResult> {
  return apiClient.post<ComparisonResult>('/api/v1/optimize/compare', request, signal ? { signal } : undefined);
}

/**
 * 提交批量任务
 */
export async function submitBatchTask(request: ComparisonRequest): Promise<{ taskId: string }> {
  return apiClient.post<{ taskId: string }>('/api/v1/optimize/batch', request);
}

// ==================== 任务管理 ====================

/**
 * 获取任务状态
 */
export async function getTaskStatus(taskId: string): Promise<TaskProgress> {
  return apiClient.get<TaskProgress>(`/api/v1/tasks/${taskId}`);
}

/**
 * 取消任务
 */
export async function cancelTask(taskId: string): Promise<{ cancelled: boolean }> {
  return apiClient.delete<{ cancelled: boolean }>(`/api/v1/tasks/${taskId}`);
}

// ==================== 导出功能 ====================

/**
 * 导出结果
 */
export function getExportUrl(resultId: string, format: ExportFormat): string {
  return `${apiClient.getBaseUrl()}/api/v1/results/${resultId}/export?format=${format}`;
}

/**
 * 批量导出
 */
export async function exportBatch(resultIds: string[], format: ExportFormat): Promise<Blob> {
  const response = await apiClient.post<Blob>('/api/v1/results/export-batch', { resultIds, format }, {
    responseType: 'blob'
  });
  return response;
}
