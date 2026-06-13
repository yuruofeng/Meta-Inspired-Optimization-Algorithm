/**
 * 多目标算法常量定义
 */

import type { Algorithm, AlgorithmCategory } from '../types';

export const MO_CATEGORY_NAMES: Record<string, string> = {
  mo: '多目标优化算法',
};

export const MO_ALGORITHM_COLORS: Record<string, string> = {
  MOALO: '#FF6B6B',
  MODA: '#4ECDC4',
  MOGOA: '#45B7D1',
  MOGWO: '#96CEB4',
  MSSA: '#FFEAA7',
};

export function getMOAlgorithmColor(algorithmId: string): string {
  return MO_ALGORITHM_COLORS[algorithmId] || '#6B7280';
}

export const MO_ALGORITHMS: Algorithm[] = [
  {
    id: 'MOALO',
    name: '多目标蚁狮优化器',
    shortName: 'MOALO',
    fullName: 'Multi-Objective Ant Lion Optimizer',
    version: '1.0.0',
    description: '多目标蚁狮优化器，将蚁狮优化算法扩展到多目标优化领域',
    category: 'swarm' as AlgorithmCategory,
    paramSchema: {
      populationSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 100, min: 1, max: 10000, description: '最大迭代次数' },
      archiveMaxSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '存档最大容量' },
    },
    reference: {
      authors: 'S. Mirjalili',
      year: 2016,
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(ArchiveSize × Dim)' },
  },
  {
    id: 'MODA',
    name: '多目标蜻蜓算法',
    shortName: 'MODA',
    fullName: 'Multi-Objective Dragonfly Algorithm',
    version: '1.0.0',
    description: '多目标蜻蜓算法，使用Pareto支配关系和存档机制',
    category: 'swarm' as AlgorithmCategory,
    paramSchema: {
      populationSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 100, min: 1, max: 10000, description: '最大迭代次数' },
      archiveMaxSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '存档最大容量' },
    },
    reference: {
      authors: 'S. Mirjalili',
      year: 2016,
    },
    complexity: { time: 'O(MaxIter × N² × Dim)', space: 'O(ArchiveSize × Dim)' },
  },
  {
    id: 'MOGOA',
    name: '多目标蚱蜢优化算法',
    shortName: 'MOGOA',
    fullName: 'Multi-Objective Grasshopper Optimization Algorithm',
    version: '1.0.0',
    description: '多目标蚱蜢优化算法，模拟蚱蜢群体社会交互行为',
    category: 'swarm' as AlgorithmCategory,
    paramSchema: {
      populationSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 100, min: 1, max: 10000, description: '最大迭代次数' },
      archiveMaxSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '存档最大容量' },
      cMax: { type: 'float', default: 1, min: 0.1, max: 10, description: '最大衰减系数' },
      cMin: { type: 'float', default: 0.00004, min: 0, max: 1, description: '最小衰减系数' },
    },
    reference: {
      authors: 'S. Mirjalili',
      year: 2017,
    },
    complexity: { time: 'O(MaxIter × N² × Dim)', space: 'O(ArchiveSize × Dim)' },
  },
  {
    id: 'MOGWO',
    name: '多目标灰狼优化器',
    shortName: 'MOGWO',
    fullName: 'Multi-Objective Grey Wolf Optimizer',
    version: '1.0.0',
    description: '多目标灰狼优化器，使用超立方体网格选择机制',
    category: 'swarm' as AlgorithmCategory,
    paramSchema: {
      populationSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 100, min: 1, max: 10000, description: '最大迭代次数' },
      archiveMaxSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '存档最大容量' },
      nGrid: { type: 'integer', default: 10, min: 5, max: 50, description: '网格 divisions' },
    },
    reference: {
      authors: 'S. Mirjalili',
      year: 2016,
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(ArchiveSize × Dim)' },
  },
  {
    id: 'MSSA',
    name: '多目标樽海鞘群算法',
    shortName: 'MSSA',
    fullName: 'Multi-Objective Salp Swarm Algorithm',
    version: '1.0.0',
    description: '多目标樽海鞘群算法，采用领导者-跟随者模型',
    category: 'swarm' as AlgorithmCategory,
    paramSchema: {
      populationSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 100, min: 1, max: 10000, description: '最大迭代次数' },
      archiveMaxSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '存档最大容量' },
    },
    reference: {
      authors: 'S. Mirjalili',
      year: 2017,
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(ArchiveSize × Dim)' },
  },
  {
    id: 'NSGAIII',
    name: '非支配排序遗传算法III',
    shortName: 'NSGA-III',
    fullName: 'Non-dominated Sorting Genetic Algorithm III',
    version: '1.0.0',
    description: 'NSGA-III算法，专门用于高维多目标优化问题，采用参考点引导搜索',
    category: 'evolutionary' as AlgorithmCategory,
    paramSchema: {
      populationSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 200, min: 1, max: 10000, description: '最大迭代次数' },
      archiveMaxSize: { type: 'integer', default: 100, min: 10, max: 1000, description: 'Pareto存档最大容量' },
    },
    reference: {
      authors: 'K. Deb, H. Jain',
      year: 2014,
      doi: '10.1109/TEVC.2013.2281535',
    },
    complexity: { time: 'O(MaxIter × N² × Dim)', space: 'O(ArchiveSize × Dim)' },
  },
  {
    id: 'MOEAD',
    name: '基于分解的多目标进化算法',
    shortName: 'MOEA/D',
    fullName: 'Multi-Objective Evolutionary Algorithm based on Decomposition',
    version: '1.0.0',
    description: 'MOEA/D算法，将多目标优化问题分解为多个单目标子问题，通过邻域协作机制优化',
    category: 'evolutionary' as AlgorithmCategory,
    paramSchema: {
      populationSize: { type: 'integer', default: 100, min: 10, max: 1000, description: '种群大小(子问题数量)' },
      maxIterations: { type: 'integer', default: 200, min: 1, max: 10000, description: '最大迭代次数' },
      archiveMaxSize: { type: 'integer', default: 100, min: 10, max: 1000, description: 'Pareto存档最大容量' },
      T: { type: 'integer', default: 20, min: 5, max: 100, description: '邻域大小' },
      delta: { type: 'float', default: 0.9, min: 0, max: 1, description: '邻域选择概率' },
      nr: { type: 'integer', default: 2, min: 1, max: 20, description: '最大更新数量' },
    },
    reference: {
      authors: 'Q. Zhang, H. Li',
      year: 2007,
      doi: '10.1109/TEVC.2007.892759',
    },
    complexity: { time: 'O(MaxIter × N × T)', space: 'O(ArchiveSize × Dim)' },
  },
];
