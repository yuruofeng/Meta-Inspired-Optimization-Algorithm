# 元启发式优化算法平台

**版本**: 2.0.0
**发布日期**: 2025
**作者**: RUOFENG YU

---

## 项目简介

本项目是一个符合工业规范的元启发式优化算法平台，实现了多种经典和改进算法，提供统一的接口、完善的测试、丰富的文档，以及现代化的Web可视化界面。

### 核心特性

- 🎯 **统一接口**: 所有算法继承 `BaseAlgorithm` 基类，遵循相同的使用模式
- 🔌 **可扩展性**: 采用注册表模式，新增算法无需修改核心代码
- 📊 **Web可视化**: 现代化React前端，支持算法对比、参数调整、实时进度
- 🚀 **RESTful API**: FastAPI后端，支持单次优化、批量任务、WebSocket实时通信
- ✅ **高质量**: 代码符合 `metaheuristic_spec.md` 规范，包含完整文档
- 📈 **标准测试**: 包含23个国际通用基准测试函数

---

## 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                     Web前端 (React 19)                       │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │
│  │ 首页    │  │算法对比 │  │单次优化 │  │历史记录 │        │
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
│  │ 17种算法 │ 23个基准函数 │ 统一结果结构 │ 注册表机制 │  │
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
│   ├── BaseAlgorithm.m            # 抽象基类
│   ├── OptimizationResult.m       # 统一结果结构
│   └── AlgorithmRegistry.m        # 算法注册表
│
├── algorithms/                    # 算法实现 (17个)
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
│   └── ssa/                       # 樽海鞘群算法
│
├── problems/                      # 问题定义
│   └── benchmark/
│       └── BenchmarkFunctions.m   # 23个基准测试函数
│
├── utils/                         # 工具函数
│   ├── Initialization.m           # 种群初始化
│   ├── RouletteWheelSelection.m   # 轮盘赌选择
│   └── BoundConstraint.m          # 边界约束
│
├── web-frontend/                  # Web前端
│   ├── src/
│   │   ├── api/                   # API客户端
│   │   ├── components/            # UI组件
│   │   ├── pages/                 # 页面
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
│   ├── demo_gwo.m                 # 灰狼优化器演示
│   ├── demo_igwo.m                # 改进灰狼演示
│   ├── demo_alo.m                 # 蚁狮优化器演示
│   ├── demo_woa.m                 # 鲸鱼优化演示
│   ├── demo_mfo.m                 # 飞蛾火焰演示
│   ├── demo_mvo.m                 # 多元宇宙演示
│   ├── demo_sca.m                 # 正弦余弦演示
│   ├── demo_ssa.m                 # 樽海鞘群演示
│   ├── demo_ga.m                  # 遗传算法演示
│   ├── demo_sa.m                  # 模拟退火演示
│   ├── demo_vpso.m                # 变速度PSO演示
│   ├── demo_vppso.m               # 变参数PSO演示
│   └── comparison.m               # 算法对比示例
│
├── tests/                         # 测试脚本
│   ├── run_all_tests.m            # 运行所有测试
│   ├── quick_validation.m         # 快速验证
│   ├── quick_validation_sca_ssa.m # SCA/SSA验证
│   ├── test_mfo_mvo.m             # MFO/MVO测试
│   └── unit/                      # 单元测试
│       ├── GWOTest.m
│       ├── MFOTest.m
│       ├── MVOTest.m
│       ├── SCATest.m
│       └── SSATest.m
│
├── start.bat                      # Windows一键启动
├── start.sh                       # Linux/macOS一键启动
├── stop.bat                       # Windows停止脚本
├── stop.sh                        # Linux/macOS停止脚本
├── README.md                      # 本文件
├── CHANGELOG.md                   # 版本变更记录
└── metaheuristic_spec.md          # 开发规范
```

---

## 已实现算法

本项目共实现 **17** 种元启发式优化算法：

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
| **SCA** | **Sine Cosine Algorithm** | **群智能** | **Mirjalili, 2016** |
| **SSA** | **Salp Swarm Algorithm** | **群智能** | **Mirjalili, 2017** |

---

## 快速开始

### 方式一：一键启动（推荐）

**Windows**:
```batch
# 双击运行或命令行执行
start.bat

# 停止服务
stop.bat
```

**Linux/macOS**:
```bash
# 添加执行权限
chmod +x start.sh stop.sh

# 启动服务
./start.sh

# 停止服务
./stop.sh
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
# 或使用uvicorn
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**3. 启动前端**

```bash
cd web-frontend
npm run dev
```

### 方式三：MATLAB直接使用

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

% 4. 运行优化 - 灰狼优化器
gwo = GWO(config);
result = gwo.run(problem);

% 或使用正弦余弦算法
sca = SCA(config);
result = sca.run(problem);

% 或使用樽海鞘群算法
ssa = SSA(config);
result = ssa.run(problem);

% 5. 查看结果
result.display();
result.plotConvergence();
```

### 新增算法使用示例

**正弦余弦算法 (SCA)**:
```matlab
% SCA 特有参数: a - 控制探索/开发平衡
config = struct(...
    'populationSize', 30, ...
    'maxIterations', 500, ...
    'a', 2 ...  % 默认值，范围[0, 10]
);
sca = SCA(config);
result = sca.run(problem);
```

**樽海鞘群算法 (SSA)**:
```matlab
% SSA 基本参数
config = struct(...
    'populationSize', 30, ...
    'maxIterations', 500 ...
);
ssa = SSA(config);
result = ssa.run(problem);
```

**多元宇宙优化器 (MVO)**:
```matlab
% MVO 特有参数: WEP_Min/WEP_Max - 虫洞存在概率范围
config = struct(...
    'populationSize', 30, ...
    'maxIterations', 500, ...
    'WEP_Min', 0.2, ...  % 最小虫洞存在概率
    'WEP_Max', 1.0 ...   % 最大虫洞存在概率
);
mvo = MVO(config);
result = mvo.run(problem);
```

**飞蛾火焰优化 (MFO)**:
```matlab
% MFO 特有参数: b - 对数螺旋形状常数
config = struct(...
    'populationSize', 30, ...
    'maxIterations', 500, ...
    'b', 1 ...  % 默认值，范围[0, 10]
);
mfo = MFO(config);
result = mfo.run(problem);
```

---

## Web界面功能

### 首页
- 平台概览和统计数据
- 快速入口（算法对比、单次优化）
- 算法分类展示

### 算法对比
- 多算法选择（按类别分组）
- 基准函数选择（23个函数）
- 参数自定义配置
- 收敛曲线对比（对数坐标）
- 统计摘要表格
- 结果导出（JSON/CSV/PNG）

### 单次优化
- 单算法深度分析
- 实时进度显示
- 详细结果展示

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

### 导出
```
GET  /api/v1/results/{id}/export?format=json|csv|mat
```

---

## 基准测试函数

平台包含23个国际通用基准测试函数：

| 函数 | 类型 | 维度 | 最优值 |
|------|------|------|--------|
| F1-F7 | 单峰 | 30 | 0 |
| F8-F13 | 多峰 | 30 | -12569.487 ~ 0 |
| F14-F23 | 固定维度 | 2-6 | 各异 |

**使用方法**:
```matlab
% 获取函数信息
info = BenchmarkFunctions.getInfo('F1');
disp(info);

% 列出所有函数
list = BenchmarkFunctions.list();
disp(list);
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

- **Seyedali Mirjalili** - ALO, GWO, WOA, DA, BBA, MFO, MVO, SCA, SSA 等算法发明者
- **M. H. Nadimi-Shahraki et al.** - IGWO, EWOA算法发明者

感谢他们为元启发式优化领域做出的贡献。

---

**作者**: RUOFENG YU
**最后更新**: 2025年2月
