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
    name: '灰狼优化器',
    shortName: 'GWO',
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
    name: '蚁狮优化器',
    shortName: 'ALO',
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
    name: '鲸鱼优化算法',
    shortName: 'WOA',
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
    name: '改进灰狼优化器',
    shortName: 'IGWO',
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
    name: '增强鲸鱼优化算法',
    shortName: 'EWOA',
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
    name: '蜻蜓算法',
    shortName: 'DA',
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
    name: '二进制蜻蜓算法',
    shortName: 'BDA',
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
    name: '二进制蝙蝠算法',
    shortName: 'BBA',
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
    name: '遗传算法',
    shortName: 'GA',
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
    name: '模拟退火算法',
    shortName: 'SA',
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
    name: '变速度粒子群算法',
    shortName: 'VPSO',
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
    name: '变参数粒子群算法',
    shortName: 'VPPSO',
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
    name: '鲸鱼-模拟退火混合算法',
    shortName: 'WOA-SA',
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
    name: '飞蛾火焰优化算法',
    shortName: 'MFO',
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
    name: '多元宇宙优化算法',
    shortName: 'MVO',
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
    name: '正弦余弦算法',
    shortName: 'SCA',
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
    name: '樽海鞘群算法',
    shortName: 'SSA',
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
    name: '蚱蜢优化算法',
    shortName: 'GOA',
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
    name: '混合粒子群-引力搜索算法',
    shortName: 'PSOGSA',
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
    name: '超学习二进制蜻蜓算法',
    shortName: 'HLBDA',
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
  {
    id: 'PSO',
    name: '粒子群优化算法',
    shortName: 'PSO',
    fullName: 'Particle Swarm Optimization',
    version: '1.0.0',
    description: '粒子群优化算法，模拟鸟群觅食行为，通过个体最优和全局最优引导搜索',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '粒子种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      w: { type: 'float', default: 0.729, min: 0, max: 1, description: '惯性权重' },
      c1: { type: 'float', default: 1.49445, min: 0, max: 4, description: '认知学习因子' },
      c2: { type: 'float', default: 1.49445, min: 0, max: 4, description: '社会学习因子' },
    },
    reference: {
      authors: 'J. Kennedy, R. Eberhart',
      year: 1995,
      doi: '10.1109/ICNN.1995.488968',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'HHO',
    name: '哈里斯鹰优化算法',
    shortName: 'HHO',
    fullName: 'Harris Hawks Optimization',
    version: '1.0.0',
    description: '哈里斯鹰优化算法，模拟鹰群协作捕食行为，支持多种攻击策略',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '鹰群种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'A.A. Heidari, S. Mirjalili et al.',
      year: 2019,
      doi: '10.1016/j.future.2019.02.028',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'ABC',
    name: '人工蜂群算法',
    shortName: 'ABC',
    fullName: 'Artificial Bee Colony',
    version: '1.0.0',
    description: '人工蜂群算法，模拟蜜蜂采蜜行为，包含雇佣蜂、观察蜂和侦查蜂三个阶段',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '蜂群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      limit: { type: 'integer', default: 100, min: 10, max: 1000, description: '放弃阈值' },
    },
    reference: {
      authors: 'D. Karaboga',
      year: 2005,
    },
    complexity: { time: 'O(MaxIter × N² × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'DE',
    name: '差分进化算法',
    shortName: 'DE',
    fullName: 'Differential Evolution',
    version: '1.0.0',
    description: '差分进化算法，基于种群差分变异的进化算法，支持多种变异策略',
    category: 'evolutionary',
    paramSchema: {
      populationSize: { type: 'integer', default: 50, min: 4, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      F: { type: 'float', default: 0.8, min: 0, max: 2, description: '缩放因子' },
      CR: { type: 'float', default: 0.9, min: 0, max: 1, description: '交叉概率' },
    },
    reference: {
      authors: 'R. Storn, K. Price',
      year: 1997,
      doi: '10.1023/A:1008202821328',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'FA',
    name: '萤火虫算法',
    shortName: 'FA',
    fullName: 'Firefly Algorithm',
    version: '1.0.0',
    description: '萤火虫算法，模拟萤火虫闪烁行为，基于光强吸引机制实现优化',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '萤火虫种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      alpha: { type: 'float', default: 0.2, min: 0, max: 1, description: '随机化参数' },
      beta0: { type: 'float', default: 1.0, min: 0, max: 10, description: '基础吸引度' },
      gamma: { type: 'float', default: 1.0, min: 0.01, max: 10, description: '光吸收系数' },
    },
    reference: {
      authors: 'X.-S. Yang',
      year: 2009,
      doi: '10.1007/978-3-642-04944-6_14',
    },
    complexity: { time: 'O(MaxIter × N² × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'SMA',
    name: '黏菌算法',
    shortName: 'SMA',
    fullName: 'Slime Mould Algorithm',
    version: '1.0.0',
    description: '黏菌算法，模拟黏菌觅食行为，通过权重机制平衡探索与开发',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '黏菌种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      z: { type: 'float', default: 0.03, min: 0, max: 1, description: '随机化参数' },
    },
    reference: {
      authors: 'S. Li, H. Chen et al.',
      year: 2020,
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'CS',
    name: '布谷鸟搜索算法',
    shortName: 'CS',
    fullName: 'Cuckoo Search',
    version: '1.0.0',
    description: '布谷鸟搜索算法，模拟布谷鸟巢寄生行为，结合Levy飞行模式',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 25, min: 5, max: 10000, description: '宿主鸟数量' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      pa: { type: 'float', default: 0.25, min: 0, max: 1, description: '外来蛋发现概率' },
    },
    reference: {
      authors: 'X.-S. Yang, S. Deb',
      year: 2009,
      doi: '10.1109/WCNC.2009.4853902',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'TLBO',
    name: '教与学优化算法',
    shortName: 'TLBO',
    fullName: 'Teaching-Learning-Based Optimization',
    version: '1.0.0',
    description: '教与学优化算法，模拟课堂教学过程，无需算法特有参数',
    category: 'evolutionary',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '班级大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'R.V. Rao et al.',
      year: 2011,
      doi: '10.1016/j.cad.2010.12.007',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'ACO',
    name: '蚁群优化算法',
    shortName: 'ACO',
    fullName: 'Ant Colony Optimization',
    version: '1.0.0',
    description: '蚁群优化算法，模拟蚂蚁觅食行为，通过信息素正反馈机制引导搜索',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '蚂蚁数量' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      archiveSize: { type: 'integer', default: 50, min: 10, max: 10000, description: '解档案大小' },
      q: { type: 'float', default: 0.5, min: 0.1, max: 10, description: '学习速率参数' },
      xi: { type: 'float', default: 0.85, min: 0, max: 1, description: '信息素衰减系数' },
    },
    reference: {
      authors: 'M. Dorigo et al.',
      year: 1996,
      doi: '10.1109/3477.484436',
    },
    complexity: { time: 'O(MaxIter × N × Dim × K)', space: 'O(N × Dim × K)' },
  },
  {
    id: 'ASO',
    name: '原子搜索优化算法',
    shortName: 'ASO',
    fullName: 'Atom Search Optimization',
    version: '1.0.0',
    description: '原子搜索优化算法，模拟原子运动行为，基于分子动力学原理',
    category: 'physics',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '原子数量' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      alpha: { type: 'float', default: 50, min: 1, max: 100, description: '衰减参数' },
      beta: { type: 'float', default: 0.2, min: 0, max: 1, description: '吸引系数' },
    },
    reference: {
      authors: 'W. Zhao, L. Wang',
      year: 2019,
    },
    complexity: { time: 'O(MaxIter × N² × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'CPO',
    name: '豪猪优化算法',
    shortName: 'CPO',
    fullName: 'Crested Porcupine Optimizer',
    version: '1.0.0',
    description: '豪猪优化算法，2024年新算法，模拟豪猪防御行为',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '豪猪种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'M.H. Nadimi-Shahraki et al.',
      year: 2024,
      doi: '10.1016/j.knosys.2024.111257',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'BWO',
    name: '白鲸优化算法',
    shortName: 'BWO',
    fullName: 'Beluga Whale Optimization',
    version: '1.0.0',
    description: '白鲸优化算法，模拟白鲸游泳、捕食和鲸落行为',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '白鲸种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'T. Zhong et al.',
      year: 2022,
      doi: '10.1016/j.knosys.2022.109215',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'HO',
    name: '蜜獾优化算法',
    shortName: 'HO',
    fullName: 'Honey Badger Optimizer',
    version: '1.0.0',
    description: '蜜獾优化算法，模拟蜜獾挖掘和蜂蜜引导行为',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '蜜獾种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
      C: { type: 'float', default: 2, min: 0, max: 10, description: '控制参数' },
      beta: { type: 'float', default: 6, min: 0, max: 20, description: '密度因子' },
    },
    reference: {
      authors: 'F.A. Hashim et al.',
      year: 2022,
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'DBO',
    name: '蜣螂优化算法',
    shortName: 'DBO',
    fullName: 'Dung Beetle Optimizer',
    version: '1.0.0',
    description: '蜣螂优化算法，模拟蜣螂滚球、舞蹈、觅食和偷窃行为',
    category: 'swarm',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '蜣螂种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'J. Xue, B. Shen',
      year: 2022,
      doi: '10.1007/s11227-022-04959-6',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
  {
    id: 'NRBO',
    name: '牛顿-拉夫森优化算法',
    shortName: 'NRBO',
    fullName: 'Newton-Raphson-Based Optimizer',
    version: '1.0.0',
    description: '牛顿-拉夫森优化算法，基于牛顿-拉夫森迭代法的元启发式算法',
    category: 'hybrid',
    paramSchema: {
      populationSize: { type: 'integer', default: 30, min: 5, max: 10000, description: '种群大小' },
      maxIterations: { type: 'integer', default: 500, min: 1, max: 100000, description: '最大迭代次数' },
    },
    reference: {
      authors: 'J. Xue, B. Shen',
      year: 2023,
      doi: '10.1016/j.knosys.2023.110552',
    },
    complexity: { time: 'O(MaxIter × N × Dim)', space: 'O(N × Dim)' },
  },
];
