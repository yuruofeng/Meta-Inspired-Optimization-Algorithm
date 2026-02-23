/**
 * 元启发式算法优化平台 - TypeScript类型定义
 * 对应MATLAB OptimizationResult.m数据结构
 */

// 算法配置参数
export interface AlgorithmConfig {
  populationSize: number;
  maxIterations: number;
  verbose?: boolean;
  [key: string]: number | boolean | string | undefined;
}

// 参数模式定义（用于动态生成表单）
export interface ParamSchema {
  type: 'integer' | 'float' | 'boolean' | 'string';
  default: number | boolean | string;
  min?: number;
  max?: number;
  description: string;
}

// 优化结果元数据
export interface ResultMetadata {
  algorithm: string;
  version: string;
  iterations: number;
  config: AlgorithmConfig;
  timestamp?: string;
}

// 优化结果（对应MATLAB OptimizationResult类）
export interface OptimizationResult {
  bestSolution: number[];
  bestFitness: number;
  convergenceCurve: number[];
  totalEvaluations: number;
  elapsedTime: number;
  metadata: ResultMetadata;
}

// 算法定义
export interface Algorithm {
  id: string;
  name: string;
  fullName: string;
  version: string;
  description: string;
  category: AlgorithmCategory;
  paramSchema: Record<string, ParamSchema>;
  reference: {
    authors: string;
    year: number;
    doi?: string;
    title?: string;
  };
  complexity: {
    time: string;
    space: string;
  };
}

// 算法类别
export type AlgorithmCategory = 'swarm' | 'evolutionary' | 'physics' | 'hybrid';

// 基准测试函数
export interface BenchmarkFunction {
  id: string;
  name: string;
  type: BenchmarkType;
  dimension: number;
  lowerBound: number | number[];
  upperBound: number | number[];
  optimalValue: number;
  description?: string;
}

export type BenchmarkType = 'Unimodal' | 'Multimodal' | 'Fixed-dimension Multimodal';

// 问题定义
export interface ProblemDefinition {
  id: string;
  type: 'benchmark' | 'custom';
  dimension: number;
  lowerBound: number | number[];
  upperBound: number | number[];
}

// 优化请求
export interface OptimizationRequest {
  algorithm: string;
  problem: ProblemDefinition;
  config: AlgorithmConfig;
}

// 对比请求
export interface ComparisonRequest {
  algorithms: string[];
  problem: ProblemDefinition;
  config: AlgorithmConfig;
  runsPerAlgorithm?: number;
}

// 对比结果
export interface ComparisonResult {
  algorithms: string[];
  functionName: string;
  results: Record<string, OptimizationResult>;
  statistics: ComparisonStatistics;
}

// 对比统计
export interface ComparisonStatistics {
  meanFitness: Record<string, number>;
  stdFitness: Record<string, number>;
  meanTime: Record<string, number>;
  rankings: Record<string, number>;
}

// 任务进度
export interface TaskProgress {
  taskId: string;
  status: TaskStatus;
  currentIteration: number;
  totalIterations: number;
  currentFitness: number;
  bestFitness: number;
  elapsedTime: number;
  estimatedRemaining: number;
  progress: number; // 0-100
}

export type TaskStatus = 'idle' | 'running' | 'completed' | 'error' | 'cancelled';

// WebSocket消息
export interface WebSocketMessage {
  type: 'progress' | 'result' | 'error' | 'connected';
  data: TaskProgress | OptimizationResult | string | null;
}

// API错误响应
export interface ApiError {
  code: string;
  message: string;
  details?: string;
}

// 导出格式
export type ExportFormat = 'json' | 'csv' | 'mat' | 'png';

// 分页参数
export interface PaginationParams {
  page: number;
  pageSize: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

// 历史记录项
export interface HistoryItem {
  id: string;
  timestamp: string;
  algorithm: string;
  functionName: string;
  bestFitness: number;
  elapsedTime: number;
  result: OptimizationResult;
}
