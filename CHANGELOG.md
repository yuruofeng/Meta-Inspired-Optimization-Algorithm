# 更新日志 (CHANGELOG)

本项目的所有重要更改都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [2.0.0] - 2025-01-15

### 重大变更 ⚠️

- **架构重构**: 从5个独立文件夹重构为统一的标准项目结构
- **接口统一**: 所有算法现在继承 `BaseAlgorithm` 基类
- **结果结构**: 优化结果现在统一返回 `OptimizationResult` 对象
- **函数签名变更**: 所有算法的调用方式已变更，旧代码需要适配

### 新增 (Added)

#### 核心基础设施
- `core/BaseAlgorithm.m` - 元启发式算法抽象基类
- `core/OptimizationResult.m` - 统一优化结果结构
- `core/AlgorithmRegistry.m` - 算法注册表，支持动态算法发现

#### 重构算法
- `algorithms/alo/ALO.m` - 蚁狮优化器 (继承BaseAlgorithm)
- `algorithms/alo/operators/RouletteWheelSelection.m` - 轮盘赌选择算子
- `algorithms/alo/operators/RandomWalk.m` - 随机游走算子
- `algorithms/gwo/GWO.m` - 灰狼优化器 (继承BaseAlgorithm)
- `algorithms/igwo/IGWO.m` - 改进灰狼优化器 (继承BaseAlgorithm)
- `algorithms/igwo/operators/BoundConstraint.m` - 边界约束算子

#### 统一工具
- `utils/Initialization.m` - 统一的种群初始化函数
- `problems/benchmark/BenchmarkFunctions.m` - 统一的23个基准测试函数库

#### 演示和文档
- `examples/demo_alo.m` - ALO算法演示脚本
- `examples/demo_gwo.m` - GWO算法演示脚本
- `examples/demo_igwo.m` - IGWO算法演示脚本
- `examples/comparison.m` - 三算法对比脚本
- `README.md` - 项目完整文档

### 变更 (Changed)

#### 接口变更
- 所有算法现在通过 `config` 结构体初始化，而非多个参数
- 优化主入口统一为 `algorithm.run(problem)` 模式
- 问题定义需传递 `problem` 对象，包含 `evaluate`, `lb`, `ub`, `dim` 字段

#### 代码优化
- **消除重复**: 合并5个 `initialization.m` 文件为1个
- **消除重复**: 合并3个 `Get_Functions_details.m` 文件为1个
- **减少代码**: 净减少约822行重复代码
- **提升文档**: 新增约1,500行文档注释

#### 性能优化
- 统一初始化函数减少4个文件
- 基准函数库减少2个文件
- 代码重复率从60%降至<5%

### 移除 (Removed)

#### 待删除 (计划中)
- `ALO/` - 原始ALO文件夹 (内容已迁移)
- `GWO/` - 原始GWO文件夹 (内容已迁移)
- `I-GWO/` - 原始I-GWO文件夹 (内容已迁移)
- `Ant Lion Optimizer Toolbox/` - GUI版本 (已废弃)
- `Grey Wolf Optimizer Toolbox/` - GUI版本 (已废弃)

#### 已移除功能
- GUI工具箱支持 (移除，仅保留命令行接口)

### 修复 (Fixed)

- 修复了原始代码中缺少输入验证的问题
- 统一了边界检查的实现方式
- 添加了配置参数的合法性检查

### 文档 (Documentation)

- 所有公开方法添加了完整的MATLAB标准文档注释
- 添加了 `PARAM_SCHEMA` 常量定义参数元数据
- 创建了完整的README.md
- 添加了使用示例和快速开始指南

---

## [1.0.0] - 2015-2021

### 原始版本

#### ALO v1.0
- 作者: Seyedali Mirjalili (2015)
- 原始代码位于 `ALO/ALO/` 文件夹

#### GWO v1.0
- 作者: Seyedali Mirjalili (2014)
- 原始代码位于 `GWO/GWO/` 文件夹

#### I-GWO v1.0
- 作者: M. H. Nadimi-Shahraki, S. Taghian, S. Mirjalili (2021)
- 原始代码位于 `I-GWO/I-GWO/` 文件夹

#### GUI Toolbox版本
- 作者: Seyedali Mirjalili
- 位于 `Ant Lion Optimizer Toolbox/` 和 `Grey Wolf Optimizer Toolbox/`

---

## 版本对比

### v1.0.0 → v2.0.0 迁移指南

**旧版本代码 (v1.x)**:
```matlab
% 旧的调用方式
[best_score, best_pos, cg_curve] = GWO(30, 500, -100, 100, 30, @fobj);
```

**新版本代码 (v2.0.0)**:
```matlab
% 新的调用方式
config = struct('populationSize', 30, 'maxIterations', 500);
[lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);

gwo = GWO(config);
result = gwo.run(problem);

% 访问结果
best_score = result.bestFitness;
best_pos = result.bestSolution;
cg_curve = result.convergenceCurve;
```

**主要差异**:
1. 配置参数通过结构体传递，而非多个独立参数
2. 问题定义封装为 `problem` 对象
3. 结果封装为 `OptimizationResult` 对象，提供更多功能

---

## 路线图

### v2.1.0 (计划中)
- [ ] 完整的测试套件 (单元测试 + 基准测试)
- [ ] 可视化工具 `FunctionPlot.m`
- [ ] 问题抽象基类 `BaseProblem.m`
- [ ] 迁移指南文档

### v2.2.0 (计划中)
- [ ] 新增PSO算法
- [ ] 新增DE算法
- [ ] 并行评估支持

### v3.0.0 (未来)
- [ ] REST API接口
- [ ] Web前端界面
- [ ] 约束优化支持
- [ ] 多目标优化支持

---

[2.0.0]: https://github.com/your-repo/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/your-repo/releases/tag/v1.0.0
