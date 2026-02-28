# 元启发式优化算法平台

**版本**: 2.1.0
**发布日期**: 2026年3月
**作者**: RUOFENG YU

---

## 项目简介

本项目是一个符合工业规范的元启发式优化算法平台，实现了多种经典和改进算法，提供统一的接口、完善的测试、丰富的文档，以及现代化的Web可视化界面。支持**单目标优化**和**多目标优化**两大类问题。

### 核心特性

- 🎯 **统一接口**: 所有算法继承 `BaseAlgorithm`/`MOBaseAlgorithm` 基类，遵循相同的使用模式
- 🔌 **可扩展性**: 采用注册表模式，新增算法无需修改核心代码
- 📊 **Web可视化**: 现代化React前端，支持算法对比、参数调整、实时进度
- 🚀 **RESTful API**: FastAPI后端，支持单次优化、批量任务、WebSocket实时通信
- ✅ **高质量**: 代码符合 `metaheuristic_spec.md` 规范，包含完整文档
- 📈 **标准测试**: 单目标23个 + 多目标13个国际通用基准测试函数
- 🔬 **多目标支持**: 5种多目标优化算法，支持ZDT/DTLZ测试集和完整性能指标

---

## 技术架构

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

### 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 前端框架 | React 19 + TypeScript | 类型安全的组件化开发 |
| 前端样式 | Tailwind CSS 4 | 现代化CSS框架 |
| 图表库 | Apache ECharts 6 | 丰富的数据可视化 |
| 状态管理 | Zustand + TanStack Query | 客户端/服务端状态分离 |
| 构建工具 | Vite 7 | 极速开发体验 |
| 后端框架 | FastAPI (Python 3.10+) | 高性能异步API |
| 计算引擎 | MATLAB R2024a | 算法实现 |
| 通信协议 | REST + WebSocket | 支持实时进度推送 |

---

## 目录结构

```
元启发优化算法验证/
├── core/                          # 核心基础设施
│   ├── BaseAlgorithm.m            # 单目标算法抽象基类
│   ├── MOBaseAlgorithm.m          # 多目标算法抽象基类
│   ├── OptimizationResult.m       # 单目标优化结果结构
│   ├── MOOptimizationResult.m     # 多目标优化结果结构
│   └── AlgorithmRegistry.m        # 算法注册表
│
├── algorithms/                    # 算法实现 (25个)
│   ├── alo/                       # 蚁狮优化器
│   ├── gwo/                       # 灰狼优化器
│   ├── igwo/                      # 改进灰狼优化器
│   ├── woa/                       # 鲸鱼优化算法
│   ├── ewoa/                      # 增强鲸鱼优化算法
│   ├── da/                        # 蜻蜓算法
│   ├── bda/                       # 二进制蜻蜓算法
│   ├── bba/                       # 二进制蝙蝠算法
│   ├── ga/                        # 遗传算法
│   ├── sa/                        # 模拟退火
│   ├── vpso/                      # 变速度粒子群
│   ├── vppso/                     # 变参数粒子群
│   ├── woa-sa/                    # 鲸鱼-模拟退火混合
│   ├── mfo/                       # 飞蛾火焰优化
│   ├── mvo/                       # 多元宇宙优化器
│   ├── sca/                       # 正弦余弦算法
│   ├── ssa/                       # 樽海鞘群算法
│   ├── goa/                       # 蚱蜢优化算法
│   ├── psogsa/                    # 混合PSO-GSA算法
│   ├── hlbda/                     # 超学习二进制蜻蜓算法
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
│   └── benchmark/
│       ├── BenchmarkFunctions.m   # 23个单目标基准测试函数
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
│       ├── GOATest.m
│       ├── PSOGSATest.m
│       ├── HLBDATest.m
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

## 已实现算法

本项目共实现 **25** 种元启发式优化算法：

### 单目标优化算法 (20个)

| 算法 | 全称 | 类别 | 参考文献 |
|------|------|------|----------|
| ALO | Ant Lion Optimizer | 群智能 | Mirjalili, 2015 |
| GWO | Grey Wolf Optimizer | 群智能 | Mirjalili, 2014 |
| IGWO | Improved GWO | 混合 | Nadimi-Shahraki, 2021 |
| WOA | Whale Optimization Algorithm | 群智能 | Mirjalili, 2016 |
| EWOA | Enhanced WOA | 混合 | Nadimi-Shahraki, 2022 |
| DA | Dragonfly Algorithm | 群智能 | Mirjalili, 2016 |
| BDA | Binary Dragonfly Algorithm | 群智能 | Mirjalili, 2016 |
| BBA | Binary Bat Algorithm | 群智能 | Mirjalili, 2014 |
| GA | Genetic Algorithm | 进化 | Holland, 1975 |
| SA | Simulated Annealing | 物理 | Kirkpatrick, 1983 |
| VPSO | Variable Velocity PSO | 群智能 | - |
| VPPSO | Variable Parameter PSO | 群智能 | - |
| WOASA | WOA-SA Hybrid | 混合 | - |
| MFO | Moth-Flame Optimization | 群智能 | Mirjalili, 2015 |
| MVO | Multi-Verse Optimizer | 群智能 | Mirjalili, 2016 |
| SCA | Sine Cosine Algorithm | 群智能 | Mirjalili, 2016 |
| SSA | Salp Swarm Algorithm | 群智能 | Mirjalili, 2017 |
| GOA | Grasshopper Optimization Algorithm | 群智能 | Saremi, 2017 |
| PSOGSA | Hybrid PSO-GSA Algorithm | 混合 | Mirjalili, 2010 |
| HLBDA | Hyper Learning Binary Dragonfly Algorithm | 群智能 | 2024 |

### 多目标优化算法 (5个)

| 算法 | 全称 | 参考文献 |
|------|------|----------|
| MOALO | Multi-Objective Ant Lion Optimizer | Mirjalili, 2016 |
| MODA | Multi-Objective Dragonfly Algorithm | Mirjalili, 2016 |
| MOGOA | Multi-Objective Grasshopper Optimization | Mirjalili, 2017 |
| MOGWO | Multi-Objective Grey Wolf Optimizer | Mirjalili, 2016 |
| MSSA | Multi-Objective Salp Swarm Algorithm | Mirjalili, 2017 |

---

## 测试问题集

### 单目标基准函数 (23个)

| 函数 | 类型 | 维度 | 最优值 |
|------|------|------|--------|
| F1-F7 | 单峰 | 30 | 0 |
| F8-F13 | 多峰 | 30 | -12569.487 ~ 0 |
| F14-F23 | 固定维度 | 2-6 | 各异 |

### 多目标测试问题 (13个)

#### ZDT系列 (2目标)
| 问题 | 维度 | Pareto前沿特性 |
|------|------|----------------|
| ZDT1 | 30 | 凸前沿 |
| ZDT2 | 30 | 非凸前沿 |
| ZDT3 | 30 | 不连续前沿 |
| ZDT4 | 10 | 多模态 |
| ZDT5 | 11 | 二进制编码 |
| ZDT6 | 10 | 非均匀分布 |

#### DTLZ系列 (可扩展目标)
| 问题 | 维度 | Pareto前沿特性 |
|------|------|----------------|
| DTLZ1 | 可变 | 线性前沿 |
| DTLZ2 | 可变 | 球面前沿 |
| DTLZ3 | 可变 | 多模态球面 |
| DTLZ4 | 可变 | 偏置球面 |
| DTLZ5 | 可变 | 退化前沿 |
| DTLZ6 | 可变 | 强偏置 |
| DTLZ7 | 可变 | 不连续前沿 |

### 多目标性能指标

| 指标 | 全称 | 说明 |
|------|------|------|
| HV | Hypervolume | 超体积，越大越好 |
| IGD | Inverted Generational Distance | 逆世代距离，越小越好 |
| GD | Generational Distance | 世代距离，越小越好 |
| Spacing | - | 解集均匀性，越小越好 |
| Spread | Δ | 扩展度，越小越好 |
| C-metric | Set Coverage | 集合覆盖度 |

---

## 快速开始

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

---

## Web界面功能

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

## API接口

### 算法管理
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

## 开发规范

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

## 系统要求

### MATLAB运行环境
- MATLAB R2020b 或更高版本
- 无需额外工具箱

### Web前端开发环境
- Node.js 18+ 和 npm 9+
- 现代浏览器 (Chrome, Firefox, Safari, Edge)

### 后端API环境
- Python 3.10+
- MATLAB Engine API for Python（可选，无MATLAB时使用模拟模式）

---

## 许可证

本项目代码采用 BSD 2-Clause 许可证。

原始算法代码版权归各自作者所有。

---

## 致谢

本项目的算法实现基于以下研究者的原创工作：

- **Seyedali Mirjalili** - ALO, GWO, WOA, DA, BBA, MFO, MVO, SCA, SSA, PSOGSA, MOALO, MODA, MOGOA, MOGWO, MSSA 等算法发明者
- **S. Saremi, A. Lewis** - GOA 蚱蜢优化算法发明者
- **M. H. Nadimi-Shahraki et al.** - IGWO, EWOA算法发明者
- **E. Zitzler et al.** - ZDT测试问题集
- **K. Deb et al.** - DTLZ测试问题集

感谢他们为元启发式优化领域做出的贡献。

---

## 更新日志

### v2.1.0 (2026年3月)
- ✨ 新增多目标优化支持 (5种算法)
- ✨ 新增ZDT/DTLZ测试问题集 (13个问题)
- ✨ 新增多目标性能指标 (Hypervolume, IGD等)
- ✨ Web前端新增多目标对比页面
- 🗑️ 移除冗余的快速验证脚本
- 🗑️ 清理过时的文档文件
- 🔧 优化项目结构

### v2.0.0 (2025年)
- 🎉 初始版本发布
- ✨ 实现20种单目标优化算法
- ✨ Web可视化界面
- ✨ RESTful API

---

**作者**: RUOFENG YU
**最后更新**: 2026年3月
