# 🧠 元启发式优化算法平台

<p align="center">
  <img src="https://img.shields.io/badge/version-2.5.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/MATLAB-R2024a-orange.svg" alt="MATLAB">
  <img src="https://img.shields.io/badge/Python-3.10+-green.svg" alt="Python">
  <img src="https://img.shields.io/badge/React-19-61DAFB.svg" alt="React">
  <img src="https://img.shields.io/badge/License-BSD_2--Clause-purple.svg" alt="License">
</p>

<p align="center">
  <a href="https://github.com/yuruofeng/metaheuristic-optimization-algorithm">
    <img src="https://img.shields.io/badge/GitHub-Repository-black.svg" alt="GitHub Repository">
  </a>
  <a href="https://github.com/yuruofeng/metaheuristic-optimization-algorithm/issues">
    <img src="https://img.shields.io/badge/Issues-Welcome-brightgreen.svg" alt="Issues">
  </a>
</p>

<p align="center">
  <strong>作者</strong>: RUOFENG YU  |  <strong>发布日期</strong>: 2026年3月
</p>

---

## 📖 项目简介

本项目是一个符合工业规范的元启发式优化算法平台，实现了多种经典和改进算法，提供统一的接口、完善的测试、丰富的文档，以及现代化的Web可视化界面。支持**单目标优化**和**多目标优化**两大类问题。

### ✨ 核心特性

|          特性          | 描述                                                                        |
| :---------------------: | :-------------------------------------------------------------------------- |
|  🎯**统一接口**  | 所有算法继承 `BaseAlgorithm`/`MOBaseAlgorithm` 基类，遵循相同的使用模式 |
|  🔌**可扩展性**  | 采用注册表模式，新增算法无需修改核心代码                                    |
|  📊**Web可视化**  | 现代化React前端，支持算法对比、参数调整、实时进度                           |
| 🚀**RESTful API** | FastAPI后端，支持单次优化、批量任务、WebSocket实时通信                      |
|   ✅**高质量**   | 代码符合 `metaheuristic_spec.md` 规范，包含完整文档和单元测试             |
|  📈**标准测试**  | 单目标23个 + 鲁棒8个 + 多目标13个国际通用基准测试函数                       |
| 🔬**多目标支持** | 5种多目标优化算法，支持ZDT/DTLZ测试集和完整性能指标                         |
|  ⚡**性能优化**  | 存档更新算法O(n log n)、Hypervolume计算支持高维快速近似                     |
| 🗺️**应用问题** | 支持MD-MTSP等实际应用场景问题                                               |

---

## 📐 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                     Web前端 (React 19)                       │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │ 首页    │  │单目标对比│  │多目标对比│  │历史记录 │        │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘        │
│       └────────────┴────────────┴────────────┘              │
│                         │ HTTP/WebSocket                     │
└─────────────────────────┼───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   后端API (FastAPI)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ REST API     │  │  WebSocket   │  │  任务管理    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                         │ MATLAB Engine API                 │
└─────────────────────────┼───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 算法引擎 (MATLAB)                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 25种算法 │ 单目标+多目标 │ ZDT/DTLZ测试集 │ 性能指标 │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 🛠 技术栈

| 层级     | 技术                     | 说明                  |
| -------- | ------------------------ | --------------------- |
| 前端框架 | React 19 + TypeScript    | 类型安全的组件化开发  |
| 前端样式 | Tailwind CSS 4           | 现代化CSS框架         |
| 图表库   | Apache ECharts 6         | 丰富的数据可视化      |
| 状态管理 | Zustand + TanStack Query | 客户端/服务端状态分离 |
| 构建工具 | Vite 7                   | 极速开发体验          |
| 后端框架 | FastAPI (Python 3.10+)   | 高性能异步API         |
| 计算引擎 | MATLAB R2024a            | 算法实现              |
| 通信协议 | REST + WebSocket         | 支持实时进度推送      |

---

## 📁 目录结构

```
元启发优化算法验证/
├── core/                          # 核心基础设施
│   ├── BaseAlgorithm.m            # 单目标算法抽象基类
│   ├── MOBaseAlgorithm.m          # 多目标算法抽象基类
│   ├── OptimizationResult.m       # 单目标优化结果结构
│   ├── MOOptimizationResult.m     # 多目标优化结果结构
│   └── AlgorithmRegistry.m        # 算法注册表
│
├── algorithms/                    # 算法实现 (40个)
│   │
│   │   # 群智能算法
│   ├── alo/                       # 蚁狮优化器
│   ├── gwo/                       # 灰狼优化器
│   ├── woa/                       # 鲸鱼优化算法
│   ├── ewoa/                      # 增强鲸鱼优化算法
│   ├── da/                        # 蜻蜓算法
│   ├── bda/                       # 二进制蜻蜓算法
│   ├── bba/                       # 二进制蝙蝠算法
│   ├── mfo/                       # 飞蛾火焰优化
│   ├── mvo/                       # 多元宇宙优化器
│   ├── ssa/                       # 樽海鞘群算法
│   ├── goa/                       # 蚱蜢优化算法
│   ├── pso/                       # 粒子群优化算法
│   ├── hho/                       # 哈里斯鹰优化算法
│   ├── abc/                       # 人工蜂群算法
│   ├── fa/                        # 萤火虫算法
│   ├── sma/                       # 黏菌算法
│   ├── cs/                        # 布谷鸟搜索算法
│   ├── aco/                       # 蚁群优化算法
│   ├── cpo/                       # 豪猪优化算法
│   ├── bwo/                       # 白鲸优化算法
│   ├── ho/                        # 蜜獾优化算法
│   ├── dbo/                       # 蜣螂优化算法
│   │
│   │   # 进化算法
│   ├── ga/                        # 遗传算法
│   ├── de/                        # 差分进化算法
│   ├── tlbo/                      # 教与学优化算法
│   │
│   │   # 物理算法
│   ├── sa/                        # 模拟退火
│   ├── aso/                       # 原子搜索优化算法
│   │
│   │   # 改进与混合算法
│   ├── igwo/                      # 改进灰狼优化器
│   ├── vpso/                      # 变速度粒子群
│   ├── vppso/                     # 变参数粒子群
│   ├── woa-sa/                    # 鲸鱼-模拟退火混合
│   ├── sca/                       # 正弦余弦算法
│   ├── psogsa/                    # 混合PSO-GSA算法
│   ├── hlbda/                     # 超学习二进制蜻蜓算法
│   ├── nrbo/                      # 牛顿-拉夫森优化算法
│   │
│   │   # 多目标优化算法
│   └── mo/                        # 多目标优化算法
│       ├── MOALO.m                # 多目标蚁狮优化器
│       ├── MODA.m                 # 多目标蜻蜓算法
│       ├── MOGOA.m                # 多目标蚱蜢优化算法
│       ├── MOGWO.m                # 多目标灰狼优化器
│       ├── MSSA.m                 # 多目标樽海鞘群算法
│       └── operators/             # 多目标操作符
│           ├── DominanceOperator.m
│           └── ArchiveManager.m
│
├── problems/                      # 问题定义
│   ├── application/
│   │   └── MDMTSPProblem.m        # 多仓库多旅行商问题
│   └── benchmark/
│       ├── BenchmarkFunctions.m   # 23个单目标基准测试函数
│       ├── RobustBenchmarkFunctions.m  # 8个鲁棒基准测试函数
│       ├── MOBenchmarkProblems.m  # 13个多目标测试问题 (ZDT/DTLZ)
│       └── MOMetrics.m            # 多目标性能评价指标
│
├── utils/                         # 工具函数
│   └── Initialization.m           # 种群初始化
│
├── shared/                        # 共享模块
│   ├── operators/                 # 共享算子
│   │   ├── crossover/             # 交叉算子
│   │   └── selection/             # 选择算子
│   ├── templates/                 # 模板
│   └── utils/                     # 工具类
│
├── web-frontend/                  # Web前端
│   ├── src/
│   │   ├── api/                   # API客户端
│   │   ├── components/            # UI组件
│   │   ├── pages/                 # 页面
│   │   │   ├── Comparison/        # 单目标对比
│   │   │   └── MOComparison/      # 多目标对比
│   │   ├── stores/                # 状态管理
│   │   └── types/                 # TypeScript类型
│   ├── package.json
│   └── vite.config.ts
│
├── api_server/                    # Python后端
│   ├── main.py                    # FastAPI应用
│   ├── models.py                  # 数据模型
│   ├── matlab_bridge.py           # MATLAB桥接
│   └── requirements.txt
│
├── examples/                      # 示例脚本
│   ├── demo_*.m                   # 各算法演示
│   ├── demo_moalgorithms.m        # 多目标算法演示
│   └── comparison.m               # 算法对比示例
│
├── tests/                         # 测试脚本
│   ├── run_all_tests.m            # 运行所有测试
│   └── unit/                      # 单元测试
│       ├── AlgorithmTestTemplate.m # 测试模板基类
│       ├── GWOTest.m              # 灰狼算法测试
│       ├── WOATest.m              # 鲸鱼算法测试
│       ├── ALOTest.m              # 蚁狮算法测试
│       ├── GOATest.m              # 蚱蜢算法测试
│       ├── MOAlgorithmTest.m      # 多目标算法测试
│       └── ...
│
├── scripts/                       # 启动脚本
│   ├── start.bat                  # Windows启动
│   └── stop.bat                   # Windows停止
│
├── docs/                          # 文档
│   └── MO_INTEGRATION_REPORT.md   # 多目标集成报告
│
├── README.md                      # 本文件
├── CONDA_SETUP_GUIDE.md           # Conda环境配置指南
└── metaheuristic_spec.md          # 开发规范
```

---

## 🧮 已实现算法

本项目共实现 **40** 种元启发式优化算法：

### 🎯 单目标优化算法 (35个)

#### 群智能算法

| 算法 | 全称                                              | 参考文献                 |
| ---- | ------------------------------------------------- | ------------------------ |
| ALO  | Ant Lion Optimizer (蚁狮优化器)                   | Mirjalili, 2015          |
| GWO  | Grey Wolf Optimizer (灰狼优化器)                  | Mirjalili, 2014          |
| WOA  | Whale Optimization Algorithm (鲸鱼优化算法)       | Mirjalili, 2016          |
| DA   | Dragonfly Algorithm (蜻蜓算法)                    | Mirjalili, 2016          |
| BDA  | Binary Dragonfly Algorithm (二进制蜻蜓算法)       | Mirjalili, 2016          |
| BBA  | Binary Bat Algorithm (二进制蝙蝠算法)             | Mirjalili, 2014          |
| MFO  | Moth-Flame Optimization (飞蛾火焰优化)            | Mirjalili, 2015          |
| MVO  | Multi-Verse Optimizer (多元宇宙优化器)            | Mirjalili, 2016          |
| SSA  | Salp Swarm Algorithm (樽海鞘群算法)               | Mirjalili, 2017          |
| GOA  | Grasshopper Optimization Algorithm (蚱蜢优化算法) | Saremi, 2017             |
| PSO  | Particle Swarm Optimization (粒子群优化算法)      | Kennedy & Eberhart, 1995 |
| HHO  | Harris Hawks Optimization (哈里斯鹰优化算法)      | Heidari, 2019            |
| ABC  | Artificial Bee Colony (人工蜂群算法)              | Karaboga, 2005           |
| FA   | Firefly Algorithm (萤火虫算法)                    | Yang, 2009               |
| SMA  | Slime Mould Algorithm (黏菌算法)                  | Li & Chen, 2020          |
| CS   | Cuckoo Search (布谷鸟搜索算法)                    | Yang & Deb, 2009         |
| ACO  | Ant Colony Optimization (蚁群优化算法)            | Dorigo, 1996             |
| CPO  | Crested Porcupine Optimizer (豪猪优化算法)        | Houssein, 2024           |
| BWO  | Beluga Whale Optimization (白鲸优化算法)          | Zhong, 2022              |
| HO   | Honey Badger Optimizer (蜜獾优化算法)             | Hashim, 2022             |
| DBO  | Dung Beetle Optimizer (蜣螂优化算法)              | Xue & Shen, 2022         |

#### 进化算法

| 算法 | 全称                                                  | 参考文献            |
| ---- | ----------------------------------------------------- | ------------------- |
| GA   | Genetic Algorithm (遗传算法)                          | Holland, 1975       |
| DE   | Differential Evolution (差分进化算法)                 | Storn & Price, 1997 |
| TLBO | Teaching-Learning-Based Optimization (教与学优化算法) | Rao, 2011           |

#### 物理算法

| 算法 | 全称                                        | 参考文献          |
| ---- | ------------------------------------------- | ----------------- |
| SA   | Simulated Annealing (模拟退火)              | Kirkpatrick, 1983 |
| ASO  | Atom Search Optimization (原子搜索优化算法) | Zhao, 2019        |

#### 改进与混合算法

| 算法   | 全称                                                         | 参考文献              |
| ------ | ------------------------------------------------------------ | --------------------- |
| IGWO   | Improved GWO (改进灰狼优化器)                                | Nadimi-Shahraki, 2021 |
| EWOA   | Enhanced WOA (增强鲸鱼优化算法)                              | Nadimi-Shahraki, 2022 |
| VPSO   | Variable Velocity PSO (变速度粒子群)                         | -                     |
| VPPSO  | Variable Parameter PSO (变参数粒子群)                        | -                     |
| WOASA  | WOA-SA Hybrid (鲸鱼-模拟退火混合)                            | -                     |
| SCA    | Sine Cosine Algorithm (正弦余弦算法)                         | Mirjalili, 2016       |
| PSOGSA | Hybrid PSO-GSA Algorithm (混合PSO-GSA)                       | Mirjalili, 2010       |
| HLBDA  | Hyper Learning Binary Dragonfly Algorithm (超学习二进制蜻蜓) | 2024                  |
| NRBO   | Newton-Raphson-Based Optimizer (牛顿-拉夫森优化算法)         | Xue & Shen, 2023      |

### 🎯 多目标优化算法 (6个)

| 算法     | 全称                                     | 参考文献        |
| -------- | ---------------------------------------- | --------------- |
| MOALO    | Multi-Objective Ant Lion Optimizer       | Mirjalili, 2016 |
| MODA     | Multi-Objective Dragonfly Algorithm      | Mirjalili, 2016 |
| MOGOA    | Multi-Objective Grasshopper Optimization | Mirjalili, 2017 |
| MOGWO    | Multi-Objective Grey Wolf Optimizer      | Mirjalili, 2016 |
| MSSA     | Multi-Objective Salp Swarm Algorithm     | Mirjalili, 2017 |
| NSGA-III | Non-dominated Sorting Genetic Algorithm III | Deb & Jain, 2014 | 高维多目标优化(k≥3)、参考点引导 |

---

## 🆕 第一阶段新增算法 (2025-03)

#### 单目标优化算法 (2个)

| 算法 | 全称                          | 参考文献              | 特点                    |
| ---- | ----------------------------- | --------------------- | ----------------------- |
| HGS  | Hunger Games Search (饥饿游戏搜索) | Yang et al., 2021 | 饥饿驱动机制、自适应权重 |
| AO  | Aquila Optimizer (天鹰优化器)    | Abualigah et al., 2021 | 四种捕猎策略、平衡探索开发 |

#### 多目标优化算法 (1个)

| 算法     | 全称                                        | 参考文献       | 特点                         |
| ------- | ------------------------------------------- | -------------- | ---------------------------- |
| NSGA-III | Non-dominated Sorting Genetic Algorithm III | Deb & Jain, 2014 | 高维多目标优化(k≥3)、参考点引导搜索 |

## 🆕 第二阶段新增算法 (2025-03)

### 单目标优化算法 (2个)

| 算法 | 全称                                        | 参考文献              | 特点                         |
| ---- | ------------------------------------------- | --------------------- | ---------------------------- |
| MPA  | Marine Predators Algorithm (海洋捕食者算法) | Faramarzi et al., 2020 | Lévy飞行与布朗运动、海洋记忆机制 |
| GTO  | Gorilla Troops Optimizer (大猩猩部队优化器) | Abdollahzadeh et al., 2021 | 银背领导者机制、探索开发平衡 |

### 多目标优化算法 (1个)

| 算法   | 全称                                              | 参考文献       | 特点                           |
| ------ | ------------------------------------------------- | -------------- | ------------------------------ |
| MOEA/D | Multi-Objective Evolutionary Algorithm based on Decomposition | Zhang & Li, 2007 | 权重向量分解、邻域协作、切比雪夫聚合 |

## 🆕 第三阶段新增算法 (2025-03)

### 单目标优化算法 (3个)

| 算法 | 全称                                    | 参考文献              | 特点                         |
| ---- | --------------------------------------- | --------------------- | ---------------------------- |
| AVOA | African Vultures Optimization Algorithm (非洲秃鹫优化) | Abdollahzadeh et al., 2022 | 饱腹率控制、多种觅食策略 |
| KOA  | Kepler Optimization Algorithm (开普勒优化算法)     | Al-Qaness et al., 2023 | 行星轨道运动、面积速度守恒 |
| RIME | Rime Optimization Algorithm (雾凇优化算法)         | Su et al., 2023 | 软硬雾凇策略、雾凇生长机制 |

---

## 🧪 测试问题集

### 单目标基准函数 (23个)

| 函数    | 类型     | 维度 | 最优值         |
| ------- | -------- | ---- | -------------- |
| F1-F7   | 单峰     | 30   | 0              |
| F8-F13  | 多峰     | 30   | -12569.487 ~ 0 |
| F14-F23 | 固定维度 | 2-6  | 各异           |

### 🛡️ 鲁棒基准函数 (8个)

这些函数专门设计用于测试优化算法的鲁棒性，包含各种障碍和困难。

| 函数ID | 名称           | 类型   | 搜索空间    | 测试目的         |
| ------ | -------------- | ------ | ----------- | ---------------- |
| R1     | TP_Biased1     | 偏置   | [-100, 100] | 处理搜索空间偏置 |
| R2     | TP_Biased2     | 偏置   | [-100, 100] | 多偏置区域搜索   |
| R3     | TP_Deceptive1  | 欺骗   | [0, 1]      | 避免局部最优陷阱 |
| R4     | TP_Deceptive2  | 欺骗   | [0, 1]      | 密集局部最优处理 |
| R5     | TP_Deceptive3  | 欺骗   | [0, 2]      | 多象限欺骗结构   |
| R6     | TP_Multimodal1 | 多模态 | [0, 1]      | 全局搜索能力     |
| R7     | TP_Multimodal2 | 多模态 | [0, 1]      | 对称多模态结构   |
| R8     | TP_Flat        | 平坦   | [0, 1]      | 平坦区域搜索     |

**参考文献**: S. Mirjalili, A. Lewis, "Obstacles and difficulties for robust benchmark problems", Information Sciences, 2016

### 🎯 多目标测试问题 (13个)

#### ZDT系列 (2目标)

| 问题 | 维度 | Pareto前沿特性 |
| ---- | ---- | -------------- |
| ZDT1 | 30   | 凸前沿         |
| ZDT2 | 30   | 非凸前沿       |
| ZDT3 | 30   | 不连续前沿     |
| ZDT4 | 10   | 多模态         |
| ZDT5 | 11   | 二进制编码     |
| ZDT6 | 10   | 非均匀分布     |

#### DTLZ系列 (可扩展目标)

| 问题  | 维度 | Pareto前沿特性 |
| ----- | ---- | -------------- |
| DTLZ1 | 可变 | 线性前沿       |
| DTLZ2 | 可变 | 球面前沿       |
| DTLZ3 | 可变 | 多模态球面     |
| DTLZ4 | 可变 | 偏置球面       |
| DTLZ5 | 可变 | 退化前沿       |
| DTLZ6 | 可变 | 强偏置         |
| DTLZ7 | 可变 | 不连续前沿     |

### 📊 多目标性能指标

| 指标     | 全称                           | 说明                 | 复杂度                                     |
| -------- | ------------------------------ | -------------------- | ------------------------------------------ |
| HV       | Hypervolume                    | 超体积，越大越好     | 2D: O(n log n), 3D: O(n²), 高维: 蒙特卡洛 |
| IGD      | Inverted Generational Distance | 逆世代距离，越小越好 | O(n×m)                                    |
| GD       | Generational Distance          | 世代距离，越小越好   | O(n×m)                                    |
| Spacing  | -                              | 解集均匀性，越小越好 | O(n²)                                     |
| Spread   | Δ                             | 扩展度，越小越好     | O(n²)                                     |
| C-metric | Set Coverage                   | 集合覆盖度           | O(n×m)                                    |

### 📦 应用问题

#### MD-MTSP (多仓库多旅行商问题)

多仓库多旅行商问题（Multi-Depot Multiple Travelling Salesman Problem）是经典TSP问题的扩展，模拟物流配送、车辆路径规划等实际应用场景。

**问题特性**:

- 类型: 组合优化问题（NP-hard）
- 目标: 最小化所有旅行商的总路径长度
- 约束: 多仓库、多旅行商、路径连续性

**使用示例**:

```matlab
% 创建默认问题
problem = MDMTSPProblem();

% 创建自定义问题
problem = MDMTSPProblem('num_cities', 20, 'num_depots', 3, ...
    'travelers_per_depot', [2, 2, 2]);

% 评估解
x = rand(1, problem.dimension) * problem.upperBound;
fitness = problem.evaluate(x);

% 获取路径详情
[fitness, routes, assignment] = problem.evaluateWithRoutes(x);

% 查看问题信息
info = problem.getProblemInfo();
fprintf('城市数: %d, 仓库数: %d, 旅行商总数: %d\n', ...
    info.num_cities, info.num_depots, info.total_travelers);
```

**参数说明**:

| 参数                | 类型         | 默认值 | 说明               |
| ------------------- | ------------ | ------ | ------------------ |
| num_cities          | int64        | 15     | 城市数量           |
| num_depots          | int64        | 2      | 仓库数量           |
| travelers_per_depot | int64 vector | [2, 2] | 各仓库旅行商数量   |
| area_size           | double       | 200    | 区域大小           |
| random_seed         | int64        | 0      | 随机种子(0=不设置) |

---

## 🚀 快速开始

### 方式一：一键启动（推荐）

**Windows**:

```batch
# 双击运行或命令行执行
scripts\start.bat

# 停止服务
scripts\stop.bat
```

启动完成后访问：

- 前端界面: http://localhost:5173
- API文档: http://localhost:8000/docs
- 健康检查: http://localhost:8000/health

### 方式二：手动启动

**1. 安装依赖**

```bash
# 后端依赖
cd api_server
pip install -r requirements.txt

# 前端依赖
cd ../web-frontend
npm install
```

**2. 启动后端**

```bash
cd api_server
python main.py
```

**3. 启动前端**

```bash
cd web-frontend
npm run dev
```

### 方式三：MATLAB直接使用

#### 单目标优化

```matlab
% 1. 获取测试函数
[lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');

% 2. 创建问题对象
problem = struct();
problem.evaluate = fobj;
problem.lb = lb;
problem.ub = ub;
problem.dim = dim;

% 3. 配置算法
config = struct('populationSize', 30, 'maxIterations', 500);

% 4. 运行优化
gwo = GWO(config);
result = gwo.run(problem);

% 5. 查看结果
result.display();
result.plotConvergence();
```

#### 多目标优化

```matlab
% 1. 获取多目标测试问题
problem = MOBenchmarkProblems.get('ZDT1');

% 2. 配置算法
config = struct(...
    'populationSize', 100, ...
    'maxIterations', 100, ...
    'archiveMaxSize', 100 ...
);

% 3. 运行多目标优化
mogwo = MOGWO(config);
result = mogwo.run(problem);

% 4. 查看Pareto前沿
result.plot();

% 5. 计算性能指标
truePF = problem.getTrueParetoFront(100);
hv = MOMetrics.hypervolume(result.paretoFront, [1.1, 1.1]);
igd = MOMetrics.IGD(result.paretoFront, truePF);
fprintf('Hypervolume: %.4f, IGD: %.6f\n', hv, igd);
```

#### 鲁棒优化测试

```matlab
% 1. 获取鲁棒测试函数
[lb, ub, dim, fobj, delta] = RobustBenchmarkFunctions.get('R3');

% 2. 创建问题对象
problem = struct();
problem.evaluate = fobj;
problem.lb = lb * ones(1, dim);
problem.ub = ub * ones(1, dim);
problem.dim = dim;

% 3. 配置算法
config = struct('populationSize', 50, 'maxIterations', 200);

% 4. 运行优化
gwo = GWO(config);
result = gwo.run(problem);

% 5. 查看结果
fprintf('最优适应度: %.6f\n', result.bestFitness);
result.plotConvergence();

% 6. 获取所有鲁棒函数列表
list = RobustBenchmarkFunctions.list();
info = RobustBenchmarkFunctions.getInfo('R3');
fprintf('函数类型: %s, 描述: %s\n', info.type, info.description);
```

---

## 💻 Web界面功能

### 首页

- 平台概览和统计数据
- 快速入口（单目标对比、多目标对比）
- 算法分类展示

### 单目标优化对比

- 20种单目标算法选择
- 23个基准函数选择
- 参数自定义配置
- 收敛曲线对比
- 统计摘要表格
- 结果导出

### 多目标优化对比

- 5种多目标算法选择
- 13个ZDT/DTLZ测试问题
- Pareto前沿可视化
- 性能指标对比 (Hypervolume, IGD, Spacing)
- 结果导出

### 历史记录

- 优化运行历史
- 结果对比分析

---

## 🔌 API接口### 算法管理

```
GET  /api/v1/algorithms           # 获取算法列表
GET  /api/v1/algorithms/{id}      # 获取算法定义
GET  /api/v1/algorithms/{id}/schema  # 获取参数模式
```

### 基准函数

```
  GET  /api/v1/benchmarks           # 获取测试函数列表
  GET  /api/v1/benchmarks/{id}      # 获取函数详情
```

### 优化执行

```
  POST /api/v1/optimize/single      # 单次优化
  POST /api/v1/optimize/compare     # 算法对比
  POST /api/v1/optimize/batch       # 批量任务
```

### 任务管理

```
  GET  /api/v1/tasks/{taskId}       # 获取任务状态
  DELETE /api/v1/tasks/{taskId}     # 取消任务
  WS   /ws/tasks/{taskId}           # WebSocket实时进度
```

---

## 📜 开发规范

本项目严格遵循 `metaheuristic_spec.md` 规范，包括:

- ✅ 目录结构标准化 (§1.1)
- ✅ 命名约定 (§1.2)
- ✅ 抽象基类设计 (§2.1)
- ✅ 算法注册机制 (§3.1)
- ✅ 可插拔算子设计 (§3.2)
- ✅ RESTful API规范 (§2.2)
- ✅ 文档注释标准 (§5.1-5.3)
- ✅ Web界面设计规范

---

## ⚙️ 系统要求

### 💻 MATLAB运行环境

- MATLAB R2020b 或更高版本
- 无需额外工具箱

### 🌐 Web前端开发环境

- Node.js 18+ 和 npm 9+
- 现代浏览器 (Chrome, Firefox, Safari, Edge)

### 🧪 前端测试

```bash
cd web-frontend

# 安装依赖（首次运行）
npm install

# 运行测试
npm test

# 运行测试（监视模式）
npm run test:watch

# 运行测试并生成覆盖率报告
npm run test:coverage
```

### ⚙️ 注意事项

#### 📊 算法参数配置

- `populationSize` 建议范围：20-100，最小值10
- `maxIterations` 建议范围:100-1000
- 多目标算法的 `archiveMaxSize` 建议与种群大小相同

#### 🚀 性能建议

- 高维问题(>30维)建议增加种群大小和迭代次数
- 多目标问题建议使用至少100次迭代以获得良好的Pareto前沿
- Hypervolume计算在高维(>3目标)时自动使用蒙特卡洛近似

#### ❓ 常见问题

1. **MATLAB路径问题**: 运行前确保已添加项目根目录到MATLAB路径

   ```matlab
   addpath(genpath('your/project/path'));
   ```
2. **内存不足**: 大规模优化问题可能需要增加MATLAB的Java堆内存
3. **收敛速度慢**: 尝试调整算法特定参数，如GWO的衰减因子或WOA的螺旋参数

---

## 📄 许可证

本项目代码采用 BSD 2-Clause 许可证。

原始算法代码版权归各自作者所有。

---

## 🙏 致谢

本项目的算法实现基于以下研究者的原创工作：

| 研究者                                 | 贡献                                                                                             |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Seyedali Mirjalili**           | ALO, GWO, WOA, DA, BBA, MFO, MVO, SCA, SSA, PSOGSA, MOALO, MODA, MOGOA, MOGWO, MSSA 等算法发明者 |
| **S. Saremi, A. Lewis**          | GOA 蚱蜢优化算法发明者                                                                           |
| **M. H. Nadimi-Shahraki et al.** | IGWO, EWOA算法发明者                                                                             |
| **E. Zitzler et al.**            | ZDT测试问题集                                                                                    |
| **K. Deb et al.**                | DTLZ测试问题集                                                                                   |
| **S. Mirjalili, A. Lewis**       | 鲁棒基准测试问题集                                                                               |

感谢他们为元启发式优化领域做出的贡献。

---

## 更新日志

### v2.5.0 (2026年3月)

**🎉 重大更新: 算法库扩展与性能优化**

#### ✨ 新增算法 (15个)

| 类别   | 算法                                                                                                                               |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| 群智能 | PSO(粒子群), HHO(哈里斯鹰), ABC(人工蜂群), FA(萤火虫), SMA(黏菌), CS(布谷鸟), ACO(蚁群), CPO(豪猪), BWO(白鲸), HO(蜜獾), DBO(蜣螂) |
| 进化   | DE(差分进化), TLBO(教与学优化)                                                                                                     |
| 物理   | ASO(原子搜索)                                                                                                                      |
| 混合   | NRBO(牛顿-拉夫森)                                                                                                                  |

#### ⚡ 性能优化

- 存档更新算法从O(n²)优化到O(n log n)
- Hypervolume计算支持2D/3D专用算法和蒙特卡洛近似

#### ✨ 新增功能

- **多目标优化**: 5种算法(MOALO, MODA, MOGOA, MOGWO, MSSA)
- **测试问题集**: ZDT/DTLZ系列(13个问题)
- **性能指标**: Hypervolume, IGD, GD, Spacing, Spread, C-metric
- **应用问题**: 多仓库多旅行商问题(MD-MTSP)
- **鲁棒基准**: 8个鲁棒测试函数(R1-R8)
- **Web前端**: 多目标对比页面、算法参数配置界面

#### 🔧 代码质量

- 修复算法语法错误和命名冲突
- 统一代码风格和变量命名规范
- 删除冗余文件，优化项目结构
- 新增单元测试和前端测试框架

#### 📚 文档更新

- README按类别重新组织算法列表
- 新增算法使用示例和测试说明
- 版本号更新至2.5.0

**统计**: 算法总数 25→40 | 单目标 20→35 | 多目标 0→5

### v2.0.0 (2025年)

- 🎉 初始版本发布
- ✨ 实现20种单目标优化算法
- ✨ Web可视化界面
- ✨ RESTful API

---

**作者**: RUOFENG YU
**最后更新**: 2026年3月
