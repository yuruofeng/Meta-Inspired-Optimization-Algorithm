/**
 * 多目标基准测试问题常量定义
 */

export interface MOProblem {
  id: string;
  name: string;
  type: 'ZDT' | 'DTLZ';
  dimension: number;
  objCount: number;
  lowerBound: number | number[];
  upperBound: number | number[];
  description: string;
}

export const MO_PROBLEM_TYPE_NAMES: Record<string, string> = {
  'ZDT': 'ZDT系列 (2目标)',
  'DTLZ': 'DTLZ系列 (可扩展目标)',
};

export const MO_PROBLEMS: MOProblem[] = [
  { id: 'ZDT1', name: 'ZDT1', type: 'ZDT', dimension: 30, objCount: 2, lowerBound: 0, upperBound: 1, description: '凸Pareto前沿' },
  { id: 'ZDT2', name: 'ZDT2', type: 'ZDT', dimension: 30, objCount: 2, lowerBound: 0, upperBound: 1, description: '非凸Pareto前沿' },
  { id: 'ZDT3', name: 'ZDT3', type: 'ZDT', dimension: 30, objCount: 2, lowerBound: 0, upperBound: 1, description: '不连续Pareto前沿' },
  { id: 'ZDT4', name: 'ZDT4', type: 'ZDT', dimension: 10, objCount: 2, lowerBound: [-5], upperBound: [5], description: '多模态问题' },
  { id: 'ZDT5', name: 'ZDT5', type: 'ZDT', dimension: 30, objCount: 2, lowerBound: 0, upperBound: 1, description: '二进制编码问题' },
  { id: 'ZDT6', name: 'ZDT6', type: 'ZDT', dimension: 10, objCount: 2, lowerBound: 0, upperBound: 1, description: '非均匀分布前沿' },
  { id: 'DTLZ1', name: 'DTLZ1', type: 'DTLZ', dimension: 7, objCount: 3, lowerBound: 0, upperBound: 1, description: '线性Pareto前沿' },
  { id: 'DTLZ2', name: 'DTLZ2', type: 'DTLZ', dimension: 12, objCount: 3, lowerBound: 0, upperBound: 1, description: '球面Pareto前沿' },
  { id: 'DTLZ3', name: 'DTLZ3', type: 'DTLZ', dimension: 12, objCount: 3, lowerBound: 0, upperBound: 1, description: '多模态球面前沿' },
  { id: 'DTLZ4', name: 'DTLZ4', type: 'DTLZ', dimension: 12, objCount: 3, lowerBound: 0, upperBound: 1, description: '偏置球面前沿' },
  { id: 'DTLZ5', name: 'DTLZ5', type: 'DTLZ', dimension: 12, objCount: 3, lowerBound: 0, upperBound: 1, description: '退化Pareto前沿' },
  { id: 'DTLZ6', name: 'DTLZ6', type: 'DTLZ', dimension: 12, objCount: 3, lowerBound: 0, upperBound: 1, description: '强偏置前沿' },
  { id: 'DTLZ7', name: 'DTLZ7', type: 'DTLZ', dimension: 22, objCount: 3, lowerBound: 0, upperBound: 1, description: '不连续Pareto前沿' },
];

export function getMOProblemById(id: string): MOProblem | undefined {
  return MO_PROBLEMS.find(p => p.id === id);
}

export function getMOProblemsByType(type: 'ZDT' | 'DTLZ'): MOProblem[] {
  return MO_PROBLEMS.filter(p => p.type === type);
}
