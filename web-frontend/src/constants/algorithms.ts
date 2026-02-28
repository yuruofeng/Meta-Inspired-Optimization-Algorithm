/**
 * 算法常量定义
 */

import type { Algorithm, AlgorithmCategory } from '../types';

// 算法类别名称映射
export const CATEGORY_NAMES: Record<AlgorithmCategory, string> = {
  swarm: '群智能算法',
  evolutionary: '进化算法',
  physics: '物理启发算法',
  hybrid: '混合算法',
};

// 算法类别颜色
export const CATEGORY_COLORS: Record<AlgorithmCategory, string> = {
  swarm: '#3B82F6',      // 蓝色
  evolutionary: '#10B981', // 绿色
  physics: '#F59E0B',    // 橙色
  hybrid: '#8B5CF6',     // 紫色
};

// 算法颜色映射（用于图表）
export const ALGORITHM_COLORS: Record<string, string> = {
  // 群智能算法（蓝色系）
  GWO: '#3B82F6',
  WOA: '#60A5FA',
  ALO: '#2563EB',
  DA: '#1D4ED8',
  BDA: '#93C5FD',
  MFO: '#1E40AF',
  MVO: '#3B82F6',
  SCA: '#60A5FA',
  SSA: '#2563EB',
  GOA: '#1E3A8A',

  // 进化算法（绿色系）
  GA: '#10B981',
  SA: '#34D399',

  // 混合算法（紫色系）
  IGWO: '#8B5CF6',
  EWOA: '#A78BFA',
  WOASA: '#7C3AED',
  PSOGSA: '#9333EA',

  // PSO变体（橙色系）
  VPSO: '#F59E0B',
  VPPSO: '#FBBF24',

  // 蝙蝠算法（红色系）
  BBA: '#EF4444',

  // 二进制算法（青色系）
  HLBDA: '#06B6D4',
};

// 默认算法配置
export const DEFAULT_CONFIG = {
  populationSize: 30,
  maxIterations: 500,
  verbose: false,
};

// 获取算法颜色
export function getAlgorithmColor(algorithmId: string): string {
  return ALGORITHM_COLORS[algorithmId] || '#6B7280';
}

// 获取类别颜色
export function getCategoryColor(category: AlgorithmCategory): string {
  return CATEGORY_COLORS[category] || '#6B7280';
}

// 算法列表（从MATLAB后端获取，此处为静态定义作为后备）
export const ALGORITHMS: Algorithm[] = [
  {
    id: 'GWO',
    name: 'GWO',
    fullName: 'Grey Wolf Optimizer',
    version: '2.0.0',
    description: '灰狼优化器，模拟灰狼群体的领导层级和狩猎行为',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'S. Mirjalili',
      year: 2014,
      doi: '10.1016/j.advengsoft.2013.12.007',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'ALO',
    name: 'ALO',
    fullName: 'Ant Lion Optimizer',
    version: '2.0.0',
    description: '蚁狮优化器，模拟蚁狮幼虫捕食蚂蚁的行为',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'S. Mirjalili',
      year: 2015,
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'WOA',
    name: 'WOA',
    fullName: 'Whale Optimization Algorithm',
    version: '2.0.0',
    description: '鲸鱼优化算法，模拟座头鲸的气泡网捕食策略',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      b: { type: 'float', default: 1, min: 0, description: '螺旋参数' },
    },
    reference: {
      authors: 'S. Mirjalili, A. Lewis',
      year: 2016,
      doi: '10.1016/j.advengsoft.2016.01.008',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'IGWO',
    name: 'IGWO',
    fullName: 'Improved Grey Wolf Optimizer',
    version: '2.0.0',
    description: '改进灰狼优化器，引入距离学习启发式搜索机制',
    category: 'hybrid',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 10, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'M.H. Nadimi-Shahraki, S. Taghian, S. Mirjalili',
      year: 2021,
      doi: '10.1016/j.eswa.2020.113917',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'EWOA',
    name: 'EWOA',
    fullName: 'Enhanced Whale Optimization Algorithm',
    version: '2.0.0',
    description: '增强鲸鱼优化算法，引入汇聚机制和Cauchy分布',
    category: 'hybrid',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      b: { type: 'float', default: 1, min: 0, description: '螺旋参数' },
      poolKappa: { type: 'float', default: 1.5, min: 1, description: '汇聚池大小倍数' },
      portionRate: { type: 'integer', default: 20, min: 1, description: '迁移比例数量' },
    },
    reference: {
      authors: 'M.H. Nadimi-Shahraki, H. Zamani, S. Mirjalili',
      year: 2022,
      doi: '10.1016/j.compbiomed.2022.105858',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim + PoolSize)' },
  },
  {
    id: 'DA',
    name: 'DA',
    fullName: 'Dragonfly Algorithm',
    version: '2.0.0',
    description: '蜻蜓算法，模拟蜻蜓静态和动态群集行为',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      separationWeight: { type: 'float', default: 0.1, min: 0, description: '分离权重' },
      alignmentWeight: { type: 'float', default: 0.1, min: 0, description: '对齐权重' },
      cohesionWeight: { type: 'float', default: 0.1, min: 0, description: '凝聚权重' },
      foodWeight: { type: 'float', default: 0.1, min: 0, description: '食物吸引权重' },
      enemyWeight: { type: 'float', default: 0.1, min: 0, description: '敌人排斥权重' },
    },
    reference: {
      authors: 'S. Mirjalili',
      year: 2016,
      doi: '10.1007/s00521-015-1920-1',
    },
    complexity: { time: 'O(MaxIter × N² × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'BDA',
    name: 'BDA',
    fullName: 'Binary Dragonfly Algorithm',
    version: '2.0.0',
    description: '二进制蜻蜓算法，使用V3传递函数进行二进制优化',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'S. Mirjalili',
      year: 2016,
    },
    complexity: { time: 'O(MaxIter × N² × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'BBA',
    name: 'BBA',
    fullName: 'Binary Bat Algorithm',
    version: '2.0.0',
    description: '二进制蝙蝠算法，使用V型传递函数将速度转换为翻转概率',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 20, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      Qmin: { type: 'float', default: 0, description: '最小频率' },
      Qmax: { type: 'float', default: 2, description: '最大频率' },
      loudness: { type: 'float', default: 0.5, min: 0, max: 1, description: '响度' },
      pulseRate: { type: 'float', default: 0.5, min: 0, max: 1, description: '脉冲率' },
    },
    reference: {
      authors: 'S. Mirjalili, S.M. Mirjalili, X. Yang',
      year: 2014,
      doi: '10.1007/s00521-013-1525-5',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'GA',
    name: 'GA',
    fullName: 'Genetic Algorithm',
    version: '2.0.0',
    description: '遗传算法，模拟自然选择和遗传机制',
    category: 'evolutionary',
    paramSchema: {
      populationSize: { type: 'integer', default: 50, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      crossoverRate: { type: 'float', default: 0.8, min: 0, max: 1, description: '交叉概率' },
      mutationRate: { type: 'float', default: 0.01, min: 0, max: 1, description: '变异概率' },
      eliteCount: { type: 'integer', default: 2, min: 0, description: '精英个体数量' },
    },
    reference: {
      authors: 'J. Holland',
      year: 1975,
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'SA',
    name: 'SA',
    fullName: 'Simulated Annealing',
    version: '2.0.0',
    description: '模拟退火算法，模拟金属退火过程',
    category: 'physics',
    paramSchema: {
      maxIterations: { type: 'integer', default: 1000, min: 1, max: 100000, description: '最大迭代次数' },
      initialTemp: { type: 'float', default: 100, min: 0, description: '初始温度' },
      finalTemp: { type: 'float', default: 0.01, min: 0, description: '终止温度' },
      coolingRate: { type: 'float', default: 0.95, min: 0, max: 1, description: '冷却速率' },
    },
    reference: {
      authors: 'S. Kirkpatrick, C.D. Gelatt, M.P. Vecchi',
      year: 1983,
    },
    complexity: { time: 'O(MaxIter × Dim)', space: 'O(Dim)' },
  },
  {
    id: 'VPSO',
    name: 'VPSO',
    fullName: 'Variable Velocity PSO',
    version: '2.0.0',
    description: '变速度粒子群优化算法',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'Project Team',
      year: 2025,
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'VPPSO',
    name: 'VPPSO',
    fullName: 'Variable Parameter PSO',
    version: '2.0.0',
    description: '变参数粒子群优化算法',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'Project Team',
      year: 2025,
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'WOASA',
    name: 'WOA-SA',
    fullName: 'WOA-SA Hybrid Algorithm',
    version: '2.0.0',
    description: '鲸鱼优化与模拟退火混合算法',
    category: 'hybrid',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'Project Team',
      year: 2025,
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'MFO',
    name: 'MFO',
    fullName: 'Moth-Flame Optimization',
    version: '2.0.0',
    description: '飞蛾火焰优化算法，模拟飞蛾横向导航行为',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 10, max: 10000, description: '飞蛾种群数量' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      b: { type: 'float', default: 1, min: 0, max: 10, description: '对数螺旋形状常数' },
    },
    reference: {
      authors: 'S. Mirjalili',
      year: 2015,
      doi: '10.1016/j.knosys.2015.07.006',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'MVO',
    name: 'MVO',
    fullName: 'Multi-Verse Optimizer',
    version: '2.0.0',
    description: '多元宇宙优化算法，模拟宇宙中白洞、黑洞和虫洞机制',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 10, max: 10000, description: '宇宙种群数量' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      WEP_Min: { type: 'float', default: 0.2, min: 0, max: 1, description: '最小虫洞存在概率' },
      WEP_Max: { type: 'float', default: 1.0, min: 0, max: 1, description: '最大虫洞存在概率' },
    },
    reference: {
      authors: 'S. Mirjalili, S.M. Mirjalili, A. Hatamlou',
      year: 2016,
      doi: '10.1007/s00521-015-1870-7',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'SCA',
    name: 'SCA',
    fullName: 'Sine Cosine Algorithm',
    version: '2.0.0',
    description: '正弦余弦算法，基于正弦和余弦函数的优化方法',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 10, max: 10000, description: '搜索代理数量' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      a: { type: 'float', default: 2, min: 0, max: 10, description: '控制探索/开发平衡参数' },
    },
    reference: {
      authors: 'S. Mirjalili',
      year: 2016,
      doi: '10.1016/j.knosys.2015.12.022',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'SSA',
    name: 'SSA',
    fullName: 'Salp Swarm Algorithm',
    version: '2.0.0',
    description: '樽海鞘群算法，模拟樽海鞘群体链状行为',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 10, max: 10000, description: '樽海鞘种群数量' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'S. Mirjalili et al.',
      year: 2017,
      doi: '10.1016/j.advengsoft.2017.07.002',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'GOA',
    name: 'GOA',
    fullName: 'Grasshopper Optimization Algorithm',
    version: '2.0.0',
    description: '蚱蜢优化算法，模拟蚱蜢群体行为的元启发式算法',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 10, max: 10000, description: '蚱蜢种群数量' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      cMax: { type: 'float', default: 1, min: 0.1, max: 10, description: '最大衰减系数' },
      cMin: { type: 'float', default: 0.00004, min: 0, max: 1, description: '最小衰减系数' },
    },
    reference: {
      authors: 'S. Saremi, S. Mirjalili, A. Lewis',
      year: 2017,
      doi: '10.1016/j.advengsoft.2017.01.004',
    },
    complexity: { time: 'O(MaxIter × N² × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'PSOGSA',
    name: 'PSOGSA',
    fullName: 'Hybrid PSO-GSA Algorithm',
    version: '2.0.0',
    description: '混合粒子群-引力搜索算法，融合PSO的社会学习能力和GSA的物理引力机制',
    category: 'hybrid',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 10, max: 10000, description: '粒子种群数量' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      wMax: { type: 'float', default: 0.9, min: 0, max: 1, description: '最大惯性权重' },
      wMin: { type: 'float', default: 0.5, min: 0, max: 1, description: '最小惯性权重' },
      G0: { type: 'float', default: 1, min: 0.1, max: 100, description: '初始引力常数' },
    },
    reference: {
      authors: 'S. Mirjalili, S.Z.M. Hashim',
      year: 2010,
    },
    complexity: { time: 'O(MaxIter × N² × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'HLBDA',
    name: 'HLBDA',
    fullName: 'Hyper Learning Binary Dragonfly Algorithm',
    version: '2.0.0',
    description: '超学习二进制蜻蜓算法，专门用于特征选择和二进制优化问题',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 10, min: 5, max: 10000, description: '蜻蜓种群数量' },
      maxIterations: { type: 'integer', default: 100, min: 1, max: 100000, description: '最大迭代次数' },
      pp: { type: 'float', default: 0.4, min: 0, max: 1, description: '个人学习概率' },
      pg: { type: 'float', default: 0.7, min: 0, max: 1, description: '全局学习概率' },
    },
    reference: {
      authors: 'Feature Selection Research',
      year: 2024,
    },
    complexity: { time: 'O(MaxIter × N² × Dim)', space: 'O(N × Dim)' },
  },
];
