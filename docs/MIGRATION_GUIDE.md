# 迁移指南 (Migration Guide)

从 v1.x 迁移到 v2.0.0 的完整指南

---

## 概述

版本 2.0.0 是一个重大版本更新，引入了不兼容的API变更。本指南将帮助您将现有代码从旧版本迁移到新版本。

---

## 主要变更

### 1. 接口变更

#### 旧版本 (v1.x)
```matlab
% 函数式调用
[best_score, best_pos, cg_curve] = GWO(SearchAgents_no, Max_iter, lb, ub, dim, fobj);
```

#### 新版本 (v2.0.0)
```matlab
% 面向对象调用
config = struct('populationSize', 30, 'maxIterations', 500);
problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);

gwo = GWO(config);
result = gwo.run(problem);

best_score = result.bestFitness;
best_pos = result.bestSolution;
cg_curve = result.convergenceCurve;
```

---

## 详细迁移步骤

### 步骤1: 更新问题定义

**旧方式**:
```matlab
% 直接使用函数句柄
fobj = @(x) sum(x.^2);
lb = -100;
ub = 100;
dim = 30;
```

**新方式**:
```matlab
% 使用BenchmarkFunctions类获取标准测试函数
[lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');

% 或自定义问题
problem = struct();
problem.evaluate = @(x) sum(x.^2);
problem.lb = -100;
problem.ub = 100;
problem.dim = 30;
```

### 步骤2: 更新算法配置

**旧方式**:
```matlab
SearchAgents_no = 30;
Max_iter = 500;
```

**新方式**:
```matlab
config = struct();
config.populationSize = 30;
config.maxIterations = 500;
config.verbose = true;  % 可选
```

### 步骤3: 更新算法调用

**旧方式**:
```matlab
[Alpha_score, Alpha_pos, Convergence_curve] = GWO(30, 500, -100, 100, 30, fobj);
```

**新方式**:
```matlab
gwo = GWO(config);
result = gwo.run(problem);
```

### 步骤4: 访问结果

**旧方式**:
```matlab
disp(Alpha_score);
plot(Convergence_curve);
```

**新方式**:
```matlab
% 显示完整结果
result.display();

% 访问单个字段
best_score = result.bestFitness;
best_pos = result.bestSolution;
evaluations = result.totalEvaluations;
time = result.elapsedTime;

% 绘制收敛曲线
result.plotConvergence();

% 保存结果
result.saveToFile('result.mat');
```

---

## 完整示例对比

### 旧版本完整代码

```matlab
% 定义目标函数
fobj = @(x) sum(x.^2);

% 设置参数
SearchAgents_no = 30;
Max_iteration = 500;
lb = -100;
ub = 100;
dim = 30;

% 运行GWO
[Alpha_score, Alpha_pos, Convergence_curve] = GWO(...
    SearchAgents_no, Max_iteration, lb, ub, dim, fobj);

% 显示结果
disp(['Best score: ', num2str(Alpha_score)]);
plot(Convergence_curve);
title('Convergence curve');
xlabel('Iteration');
ylabel('Best score');
```

### 新版本完整代码

```matlab
% 获取基准函数
[lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');

% 配置算法
config = struct('populationSize', 30, 'maxIterations', 500);

% 定义问题
problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);

% 运行优化
gwo = GWO(config);
result = gwo.run(problem);

% 显示结果
result.display();

% 绘制收敛曲线
result.plotConvergence('Title', 'GWO Convergence');
```

---

## 功能映射表

| 旧版本 | 新版本 | 说明 |
|--------|--------|------|
| `GWO(N, MaxIter, lb, ub, dim, fobj)` | `gwo = GWO(config); result = gwo.run(problem)` | 调用方式 |
| `Alpha_score` | `result.bestFitness` | 最优适应度 |
| `Alpha_pos` | `result.bestSolution` | 最优解 |
| `Convergence_curve` | `result.convergenceCurve` | 收敛曲线 |
| N/A | `result.totalEvaluations` | 总评估次数 (新增) |
| N/A | `result.elapsedTime` | 运行时间 (新增) |
| N/A | `result.display()` | 结果显示 (新增) |
| N/A | `result.plotConvergence()` | 收敛曲线绘制 (新增) |
| N/A | `result.saveToFile()` | 保存结果 (新增) |

---

## 初始化函数变更

### 旧方式
```matlab
% 直接调用局部函数
Positions = initialization(SearchAgents_no, dim, ub, lb);
```

### 新方式
```matlab
% 调用统一的工具函数
Positions = Initialization(SearchAgents_no, dim, ub, lb);
```

**注意**: 函数名首字母大写，功能完全相同。

---

## 基准函数变更

### 旧方式
```matlab
% 调用局部函数
[lb, ub, dim, fobj] = Get_Functions_details('F1');
```

### 新方式
```matlab
% 使用BenchmarkFunctions类
[lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');

% 获取函数信息
info = BenchmarkFunctions.getInfo('F1');

% 列出所有函数
list = BenchmarkFunctions.list();
```

---

## 新增功能

v2.0.0 引入了以下新功能：

### 1. OptimizationResult 对象

```matlab
result = gwo.run(problem);

% 基本属性
result.bestSolution        % 最优解
result.bestFitness         % 最优适应度
result.convergenceCurve    % 收敛曲线
result.totalEvaluations    % 总评估次数
result.elapsedTime         % 运行时间
result.metadata            % 元数据

% 方法
result.display()           % 显示结果摘要
result.plotConvergence()   % 绘制收敛曲线
result.saveToFile()        % 保存到文件
result.compare(otherResult) % 对比两个结果
```

### 2. 算法注册表

```matlab
% 注册算法
ALO.register();
GWO.register();
IGWO.register();

% 获取算法
algClass = AlgorithmRegistry.getAlgorithm('GWO');

% 列出所有算法
algorithms = AlgorithmRegistry.listAlgorithms();
```

### 3. 参数Schema

```matlab
% 获取算法参数元数据
schema = GWO.PARAM_SCHEMA;

% 动态生成UI
for field = fieldnames(schema)'
    param = schema.(field{1});
    fprintf('%s: %s (default: %s)\n', ...
        field{1}, param.description, string(param.default));
end
```

---

## 已废弃的功能

以下功能在v2.0.0中已被移除：

1. **GUI Toolbox** - 移除了MATLAB GUI版本，仅保留命令行接口
2. **函数式接口** - 不再支持旧的函数式调用方式
3. **重复的工具函数** - 所有重复文件已合并

---

## 常见问题 (FAQ)

### Q1: 为什么结果与旧版本不同？

**A**: 可能的原因：
1. 随机种子不同 - 使用 `rng(seed)` 设置相同种子
2. 参数设置不同 - 检查 `config` 结构体
3. 算法改进 - IGWO相比原始GWO有改进

### Q2: 如何在旧项目中使用新版本？

**A**: 选项1: 重构代码（推荐）
```matlab
% 将旧代码重构为新接口
```

选项2: 创建适配器
```matlab
function [best_score, best_pos, cg_curve] = GWO_legacy(N, MaxIter, lb, ub, dim, fobj)
    config = struct('populationSize', N, 'maxIterations', MaxIter);
    problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);

    gwo = GWO(config);
    result = gwo.run(problem);

    best_score = result.bestFitness;
    best_pos = result.bestSolution;
    cg_curve = result.convergenceCurve;
end
```

### Q3: 性能是否有变化？

**A**: 核心算法逻辑未改变，性能应该相当。新增功能（如结果对象）带来的开销可忽略不计。

### Q4: 如何报告迁移问题？

**A**: 请通过内部工单系统提交，包含：
- 原始代码
- 迁移后的代码
- 错误信息
- MATLAB版本

---

## 检查清单

迁移前请确认：

- [ ] 已阅读本迁移指南
- [ ] 已备份原始代码
- [ ] 已更新问题定义格式
- [ ] 已更新算法配置方式
- [ ] 已更新结果访问方式
- [ ] 已测试基本功能
- [ ] 已更新测试脚本
- [ ] 已验证结果一致性

---

## 获取帮助

- **文档**: 参见 `README.md` 和 `docs/` 目录
- **示例**: 参见 `examples/` 目录
- **变更**: 参见 `CHANGELOG.md`

---

**祝迁移顺利！**
