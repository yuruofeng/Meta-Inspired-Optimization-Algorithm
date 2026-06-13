/**
 * 鲁棒基准测试函数常量定义
 * 
 * 这些函数专门设计用于测试优化算法的鲁棒性，
 * 包含各种障碍和困难，如偏置、欺骗性、多模态和平坦区域。
 * 
 * 参考文献:
 *   S. Mirjalili, A. Lewis, "Obstacles and difficulties for robust 
 *   benchmark problems: A novel penalty-based robust optimisation 
 *   method", Information Sciences, Vol. 328, pp. 485-509, 2016.
 */

import type { RobustBenchmarkFunction, RobustBenchmarkType } from '../types';

// 鲁棒函数类型名称映射
export const ROBUST_TYPE_NAMES: Record<RobustBenchmarkType, string> = {
  'Biased': '偏置函数',
  'Deceptive': '欺骗函数',
  'Multimodal': '多模态函数',
  'Flat': '平坦函数',
};

// 鲁棒函数类型描述
export const ROBUST_TYPE_DESCRIPTIONS: Record<RobustBenchmarkType, string> = {
  'Biased': '测试算法处理搜索空间偏置的能力',
  'Deceptive': '测试算法避免被局部最优欺骗的能力',
  'Multimodal': '测试算法处理多个局部最优的能力',
  'Flat': '测试算法在平坦区域（梯度信息少）的搜索能力',
};

// 鲁棒基准函数列表
export const ROBUST_BENCHMARK_FUNCTIONS: RobustBenchmarkFunction[] = [
  // 偏置函数 R1-R2
  {
    id: 'R1',
    name: 'TP_Biased1',
    type: 'Biased',
    dimension: 2,
    lowerBound: -100,
    upperBound: 100,
    delta: 1,
    description: '偏置测试问题1 - 搜索空间存在偏置，最优解不在中心'
  },
  {
    id: 'R2',
    name: 'TP_Biased2',
    type: 'Biased',
    dimension: 2,
    lowerBound: -100,
    upperBound: 100,
    delta: 1,
    description: '偏置测试问题2 - 多个偏置区域，增加搜索难度'
  },

  // 欺骗函数 R3-R5
  {
    id: 'R3',
    name: 'TP_Deceptive1',
    type: 'Deceptive',
    dimension: 2,
    lowerBound: 0,
    upperBound: 1,
    delta: 0.01,
    description: '欺骗测试问题1 - 多个局部最优陷阱，容易误导算法'
  },
  {
    id: 'R4',
    name: 'TP_Deceptive2',
    type: 'Deceptive',
    dimension: 2,
    lowerBound: 0,
    upperBound: 1,
    delta: 0.01,
    description: '欺骗测试问题2 - 密集的局部最优分布'
  },
  {
    id: 'R5',
    name: 'TP_Deceptive3',
    type: 'Deceptive',
    dimension: 2,
    lowerBound: 0,
    upperBound: 2,
    delta: 0.01,
    description: '欺骗测试问题3 - 四个象限有不同的欺骗结构'
  },

  // 多模态函数 R6-R7
  {
    id: 'R6',
    name: 'TP_Multimodal1',
    type: 'Multimodal',
    dimension: 2,
    lowerBound: 0,
    upperBound: 1,
    delta: 0.01,
    description: '多模态测试问题1 - 大量局部最优，测试全局搜索能力'
  },
  {
    id: 'R7',
    name: 'TP_Multimodal2',
    type: 'Multimodal',
    dimension: 2,
    lowerBound: 0,
    upperBound: 1,
    delta: 0.01,
    description: '多模态测试问题2 - 对称的多模态结构'
  },

  // 平坦函数 R8
  {
    id: 'R8',
    name: 'TP_Flat',
    type: 'Flat',
    dimension: 2,
    lowerBound: 0,
    upperBound: 1,
    delta: 0.01,
    description: '平坦区域测试问题 - 大面积平坦区域，梯度信息稀少'
  },
];

// 根据ID获取鲁棒基准函数
export function getRobustBenchmarkById(id: string): RobustBenchmarkFunction | undefined {
  return ROBUST_BENCHMARK_FUNCTIONS.find(f => f.id === id);
}

// 根据类型获取鲁棒基准函数
export function getRobustBenchmarksByType(type: RobustBenchmarkType): RobustBenchmarkFunction[] {
  return ROBUST_BENCHMARK_FUNCTIONS.filter(f => f.type === type);
}

// 获取所有鲁棒基准函数ID列表
export function getRobustBenchmarkIds(): string[] {
  return ROBUST_BENCHMARK_FUNCTIONS.map(f => f.id);
}
