/**
 * 基准测试函数常量定义
 */

import type { BenchmarkFunction, BenchmarkType } from '../types';

// 基准函数类型名称映射
export const BENCHMARK_TYPE_NAMES: Record<BenchmarkType, string> = {
  'Unimodal': '单峰函数',
  'Multimodal': '多峰函数',
  'Fixed-dimension Multimodal': '固定维度多峰函数',
};

// 基准函数列表
export const BENCHMARK_FUNCTIONS: BenchmarkFunction[] = [
  // 单峰函数 F1-F7
  { id: 'F1', name: 'Sphere', type: 'Unimodal', dimension: 30, lowerBound: -100, upperBound: 100, optimalValue: 0, description: '简单的凸函数，用于测试收敛性' },
  { id: 'F2', name: 'Rosenbrock', type: 'Unimodal', dimension: 30, lowerBound: -30, upperBound: 30, optimalValue: 0, description: '经典的优化测试函数，有狭窄的谷底' },
  { id: 'F3', name: 'Step', type: 'Unimodal', dimension: 30, lowerBound: -100, upperBound: 100, optimalValue: 0, description: '阶梯函数，测试算法处理不连续的能力' },
  { id: 'F4', name: 'Quartic', type: 'Unimodal', dimension: 30, lowerBound: -1.28, upperBound: 1.28, optimalValue: 0, description: '四次函数，带有噪声' },
  { id: 'F5', name: 'Schwefel 2.22', type: 'Unimodal', dimension: 30, lowerBound: -10, upperBound: 10, optimalValue: 0 },
  { id: 'F6', name: 'Schwefel 1.2', type: 'Unimodal', dimension: 30, lowerBound: -65.536, upperBound: 65.536, optimalValue: 0 },
  { id: 'F7', name: 'Schwefel 2.21', type: 'Unimodal', dimension: 30, lowerBound: -100, upperBound: 100, optimalValue: 0 },

  // 多峰函数 F8-F13
  { id: 'F8', name: 'Schwefel', type: 'Multimodal', dimension: 30, lowerBound: -500, upperBound: 500, optimalValue: -12569.487, description: '全局最优点远离搜索空间中心' },
  { id: 'F9', name: 'Rastrigin', type: 'Multimodal', dimension: 30, lowerBound: -5.12, upperBound: 5.12, optimalValue: 0, description: '高度多峰，大量局部最优' },
  { id: 'F10', name: 'Ackley', type: 'Multimodal', dimension: 30, lowerBound: -32, upperBound: 32, optimalValue: 0, description: '具有几乎平坦的区域' },
  { id: 'F11', name: 'Griewank', type: 'Multimodal', dimension: 30, lowerBound: -600, upperBound: 600, optimalValue: 0 },
  { id: 'F12', name: 'Penalized 1', type: 'Multimodal', dimension: 30, lowerBound: -50, upperBound: 50, optimalValue: 0 },
  { id: 'F13', name: 'Penalized 2', type: 'Multimodal', dimension: 30, lowerBound: -50, upperBound: 50, optimalValue: 0 },

  // 固定维度多峰函数 F14-F23
  { id: 'F14', name: 'Shekel 5', type: 'Fixed-dimension Multimodal', dimension: 2, lowerBound: -65.536, upperBound: 65.536, optimalValue: 0.998 },
  { id: 'F15', name: 'Kowalik', type: 'Fixed-dimension Multimodal', dimension: 4, lowerBound: -5, upperBound: 5, optimalValue: 0.0003075 },
  { id: 'F16', name: 'Six-Hump Camel', type: 'Fixed-dimension Multimodal', dimension: 2, lowerBound: -5, upperBound: 5, optimalValue: -1.0316285 },
  { id: 'F17', name: 'Branin', type: 'Fixed-dimension Multimodal', dimension: 2, lowerBound: -5, upperBound: 15, optimalValue: 0.397887 },
  { id: 'F18', name: 'Goldstein-Price', type: 'Fixed-dimension Multimodal', dimension: 2, lowerBound: -2, upperBound: 2, optimalValue: 3 },
  { id: 'F19', name: 'Hartman 3', type: 'Fixed-dimension Multimodal', dimension: 3, lowerBound: 0, upperBound: 1, optimalValue: -3.86 },
  { id: 'F20', name: 'Hartman 6', type: 'Fixed-dimension Multimodal', dimension: 6, lowerBound: 0, upperBound: 1, optimalValue: -3.32 },
  { id: 'F21', name: 'Shekel 7', type: 'Fixed-dimension Multimodal', dimension: 4, lowerBound: 0, upperBound: 10, optimalValue: -10.1532 },
  { id: 'F22', name: 'Shekel 10', type: 'Fixed-dimension Multimodal', dimension: 4, lowerBound: 0, upperBound: 10, optimalValue: -10.4029 },
  { id: 'F23', name: 'Shekel 10 (alt)', type: 'Fixed-dimension Multimodal', dimension: 4, lowerBound: 0, upperBound: 10, optimalValue: -10.5364 },
];

// 根据ID获取基准函数
export function getBenchmarkById(id: string): BenchmarkFunction | undefined {
  return BENCHMARK_FUNCTIONS.find(f => f.id === id);
}

// 根据类型获取基准函数
export function getBenchmarksByType(type: BenchmarkType): BenchmarkFunction[] {
  return BENCHMARK_FUNCTIONS.filter(f => f.type === type);
}
