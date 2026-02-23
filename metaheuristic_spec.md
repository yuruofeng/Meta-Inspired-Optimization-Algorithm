# 元启发式算法代码优化规范

**Metaheuristic Algorithm Code Optimization Standard**

---

| 版本号 | v1.0.0 |
|--------|--------|
| 文档状态 | 正式发布 |
| 发布日期 | 2025年 |
| 适用算法 | 遗传算法 (GA) · 粒子群优化 (PSO) · 模拟退火 (SA) · 差分进化 (DE) · 蚁群优化 (ACO) · 鲸鱼优化 (WOA) 等 |
| 目标读者 | 算法工程师、后端开发人员、前端集成开发人员 |
| 作者 | RUOFENG YU |

---

## 0 导言与规范概述

本规范旨在为元启发式算法（Metaheuristic Algorithms）的工程化实现提供全面、统一的标准框架。元启发式算法种类繁多，涵盖遗传算法（GA）、粒子群优化（PSO）、模拟退火（SA）、差分进化（DE）、蚁群优化（ACO）等数十种经典及新兴算法。在多团队协同开发的工程实践中，缺乏统一规范往往导致代码风格迥异、接口不兼容、可维护性低下等问题。

本规范从代码结构、接口设计、扩展性、性能、文档、测试、错误处理及版本控制八个维度构建完整的工程规范体系，为后续通用前端的接入提供坚实的标准化基础。

> **📌 注意：** 本规范以 MATLAB 为主要示例语言，所有设计原则同样适用于 Java、C++、TypeScript 等语言的实现。

---

## 1 代码结构标准化

### 1.1 标准目录结构

所有元启发式算法项目须遵循以下统一目录结构，以确保不同团队和不同算法实现之间具备一致的代码组织方式：

```
metaheuristic_platform/
├── core/
│   +BaseAlgorithm.m           % 抽象基类
│   +BaseProblem.m             % 问题定义抽象层
│   +Population.m              % 种群管理工具
│   +Solution.m                % 解结构定义
├── algorithms/
│   +ga/                       % 遗传算法模块
│   │   +GeneticAlgorithm.m
│   │   +operators/            % 交叉、变异、选择算子
│   └── config.m
│   +pso/                      % 粒子群优化模块
│   +sa/                       % 模拟退火模块
│   +de/                       % 差分进化模块
│   +aco/                      % 蚁群优化模块
├── problems/
│   +benchmark/                % 标准测试问题
│   +custom/                   % 自定义问题
├── utils/
│   +Logger.m                  % 统一日志工具
│   +Metrics.m                 % 性能评价指标
│   +Visualization.m           % 收敛曲线可视化
│   +Parallel.m                % 并行计算支持
├── api/
│   +Routes.m                  % REST API 路由
│   +Schemas.m                 % 请求/响应 Schema
│   +Middleware.m              % 错误处理中间件
├── tests/
│   +unit/                     % 单元测试
│   +integration/              % 集成测试
│   +benchmark/                % 性能基准测试
├── docs/
│   api_reference.md
│   algorithm_guides/
├── configs/
│   algorithm_defaults.yaml
├── projectConfig.m            % MATLAB 项目配置
└── README.md
```

### 1.2 命名约定

所有命名规范须严格遵守下表所列标准，保持跨语言实现的一致语义：

| 命名类型 | 规范示例 |
|----------|----------|
| 模块/文件名 | `GeneticAlgorithm.m`（UpperCamelCase） |
| 类名 | `GeneticAlgorithm`（UpperCamelCase） |
| 方法名 | `runOptimization`（lowerCamelCase） |
| 属性名 | `populationSize`（lowerCamelCase） |
| 常量 | `DEFAULT_POP_SIZE`（UPPER_SNAKE_CASE） |
| 私有成员 | `p_internalState`（p 前缀） |

### 1.3 模块职责划分

严格遵守单一职责原则（SRP），各模块职责划分如下：

- **core 层**：仅定义抽象接口与通用数据结构
- **algorithms 层**：实现具体算法逻辑，不得包含 I/O 或网络调用
- **utils 层**：提供无状态工具函数
- **api 层**：负责协议适配与参数验证
- **tests 层**：独立于业务逻辑，禁止在测试代码中引入算法具体实现细节

---

## 2 接口设计规范

### 2.1 抽象基类设计

所有算法实现类须继承统一的抽象基类 `BaseAlgorithm`，该基类定义了算法生命周期的完整接口契约：

```matlab
classdef OptimizationResult
    properties
        bestSolution        % 最优解
        bestFitness double  % 最优适应度值
        convergenceCurve double % 每代最优值列表
        totalEvaluations int64  % 总评估次数
        elapsedTime double      % 运行时长（秒）
        metadata struct         % 元数据
    end
    
    methods
        function obj = OptimizationResult(varargin)
            % 构造函数支持键值对参数
            p = inputParser;
            addParameter(p, 'bestSolution', []);
            addParameter(p, 'bestFitness', Inf);
            addParameter(p, 'convergenceCurve', []);
            addParameter(p, 'totalEvaluations', 0);
            addParameter(p, 'elapsedTime', 0);
            addParameter(p, 'metadata', struct());
            parse(p, varargin{:});
            
            obj.bestSolution = p.Results.bestSolution;
            obj.bestFitness = p.Results.bestFitness;
            obj.convergenceCurve = p.Results.convergenceCurve;
            obj.totalEvaluations = p.Results.totalEvaluations;
            obj.elapsedTime = p.Results.elapsedTime;
            obj.metadata = p.Results.metadata;
        end
    end
end
```

```matlab
classdef (Abstract) BaseAlgorithm < handle
    properties (Access = protected)
        config struct
        logger
    end
    
    methods
        function obj = BaseAlgorithm(configStruct)
            obj.config = obj.validateConfig(configStruct);
            obj.logger = Logger(obj.classname);
        end
        
        function result = run(obj, problem)
            % 模板方法：定义优化主流程（不可覆盖）
            obj.initialize(problem);
            while ~obj.shouldStop()
                obj.iterate();
            end
            result = obj.collectResult();
        end
    end
    
    methods (Abstract)
        initialize(obj, problem)
        iterate(obj)
        tf = shouldStop(obj)
        validatedConfig = validateConfig(obj, config)
    end
    
    methods (Access = protected)
        function result = collectResult(obj)
            % 子类实现具体结果收集逻辑
        end
    end
end
```

### 2.2 REST API 接口规范

#### 2.2.1 运行算法端点

```
POST  /api/v1/algorithms/{algorithm_id}/run
```

**请求体（Request Body）：**

```json
{
  "problem": {
    "type": "continuous",
    "dimension": 30,
    "bounds": [[-100, 100]],
    "objective": "minimize",
    "constraints": []
  },
  "config": {
    "population_size": 50,
    "max_iterations": 500,
    "seed": 42,
    "parallel": false
  },
  "algorithm_params": {
    "mutation_rate": 0.01,
    "crossover_rate": 0.9
  },
  "callback_url": "https://..."
}
```

**响应体（Response Body）—— 同步模式：**

```json
{
  "status": "success",
  "task_id": "task_abc123",
  "result": {
    "best_solution": [1.2, -3.4, ...],
    "best_fitness": 0.00142,
    "convergence_curve": [128.4, 56.2, ...],
    "total_evaluations": 25000,
    "elapsed_time": 3.72
  },
  "metadata": {
    "algorithm": "GeneticAlgorithm",
    "version": "1.2.0",
    "timestamp": "2025-01-15T10:30:00Z"
  }
}
```

#### 2.2.2 其他标准端点

除运行端点外，平台还须暴露以下标准端点，供前端进行算法发现与状态管理：

| 端点 | 说明 |
|------|------|
| `GET /api/v1/algorithms` | 获取所有可用算法列表 |
| `GET /api/v1/algorithms/{id}` | 获取算法详情及参数 Schema |
| `GET /api/v1/tasks/{task_id}` | 查询异步任务状态 |
| `DELETE /api/v1/tasks/{task_id}` | 取消正在运行的任务 |
| `GET /api/v1/algorithms/{id}/defaults` | 获取默认参数配置 |
| `POST /api/v1/problems/validate` | 验证问题定义合法性 |
| `GET /api/v1/health` | 健康检查 |

> **📌 注意：** 所有端点均须支持 CORS，并通过 `Content-Type: application/json` 进行通信。异步任务须支持 WebSocket 推送实时进度（路径：`/ws/tasks/{task_id}`）。

---

## 3 扩展性设计要求

### 3.1 算法注册机制

平台采用注册表模式（Registry Pattern）管理所有算法实现。新算法只需在注册表中注册，无需修改任何核心代码，实现真正的开闭原则（OCP）：

```matlab
% core/AlgorithmRegistry.m
classdef AlgorithmRegistry < handle
    properties (Constant, Access = private)
        registry = containers.Map()
    end
    
    methods (Static)
        function register(name, version, algorithmClass)
            key = sprintf('%s:%s', name, version);
            AlgorithmRegistry.registry(key) = algorithmClass;
        end
        
        function algorithmClass = getAlgorithm(name, varargin)
            if nargin > 1
                version = varargin{1};
                key = sprintf('%s:%s', name, version);
            else
                % 查找最新版本
                keys = AlgorithmRegistry.registry.keys;
                matchingKeys = keys(startsWith(keys, [name ':']));
                if isempty(matchingKeys)
                    error('AlgorithmNotFoundError', ...
                        'Algorithm %s not found in registry', name);
                end
                key = matchingKeys{end};
            end
            algorithmClass = AlgorithmRegistry.registry(key);
        end
    end
end
```

```matlab
% 新算法接入示例
classdef WhaleOptimizationAlgorithm < BaseAlgorithm
    methods
        function obj = WhaleOptimizationAlgorithm(config)
            obj = obj@BaseAlgorithm(config);
        end
        
        function initialize(obj, problem)
            % 初始化逻辑
        end
        
        function iterate(obj)
            % 迭代逻辑
        end
        
        function tf = shouldStop(obj)
            % 停止条件
        end
        
        function validatedConfig = validateConfig(obj, config)
            % 配置验证
        end
    end
    
    methods (Static)
        function register()
            AlgorithmRegistry.register('whale_optimization', '1.0.0', ...
                @WhaleOptimizationAlgorithm);
        end
    end
end
```

### 3.2 可插拔算子设计

算法内部的核心操作（如遗传算法中的选择、交叉、变异算子）须抽象为独立的算子接口，允许自由组合和替换，而不影响算法主体逻辑：

```matlab
% algorithms/ga/operators/SelectionOperator.m
classdef (Abstract) SelectionOperator < handle
    methods (Abstract)
        selectedIndices = select(obj, population, fitnessValues, n)
    end
end
```

```matlab
% algorithms/ga/operators/TournamentSelection.m
classdef TournamentSelection < SelectionOperator
    properties
        tournamentSize int32 = 3
    end
    
    methods
        function obj = TournamentSelection(tournamentSize)
            if nargin > 0
                obj.tournamentSize = tournamentSize;
            end
        end
        
        function selectedIndices = select(obj, population, fitnessValues, n)
            popSize = size(population, 1);
            selectedIndices = zeros(n, 1);
            
            for i = 1:n
                candidates = randperm(popSize, obj.tournamentSize);
                [~, winnerIdx] = min(fitnessValues(candidates));
                selectedIndices(i) = candidates(winnerIdx);
            end
        end
    end
end
```

```matlab
% algorithms/ga/operators/RouletteWheelSelection.m
classdef RouletteWheelSelection < SelectionOperator
    methods
        function selectedIndices = select(obj, population, fitnessValues, n)
            popSize = size(population, 1);
            
            % 将适应度转换为选择概率（最小化问题需反转）
            maxFitness = max(fitnessValues);
            probs = (maxFitness - fitnessValues + 1);
            probs = probs / sum(probs);
            
            % 轮盘赌选择
            cumProbs = cumsum(probs);
            selectedIndices = zeros(n, 1);
            for i = 1:n
                r = rand();
                selectedIndices(i) = find(cumProbs >= r, 1, 'first');
            end
        end
    end
end
```

```matlab
% GA 通过依赖注入接受算子
classdef GeneticAlgorithm < BaseAlgorithm
    properties
        selectionOperator
        crossoverOperator
        mutationOperator
    end
    
    methods
        function obj = GeneticAlgorithm(config)
            obj = obj@BaseAlgorithm(config);
            
            % 通过工厂创建算子
            selectionType = 'tournament';
            if isfield(config, 'selection')
                selectionType = config.selection;
            end
            obj.selectionOperator = OperatorFactory.create(...
                'selection', selectionType);
            obj.crossoverOperator = OperatorFactory.create(...
                'crossover', config.get('crossover', 'single_point'));
            obj.mutationOperator = OperatorFactory.create(...
                'mutation', config.get('mutation', 'gaussian'));
        end
    end
end
```

### 3.3 问题定义扩展

用户自定义优化问题须通过继承 `BaseProblem` 并实现 `evaluate()` 方法来接入平台。平台对问题类型不做限制，支持连续、离散、多目标等各类问题形式。评估函数的输入输出格式由平台统一规范，确保所有算法均可无缝对接任意合规问题。

```matlab
classdef (Abstract) BaseProblem < handle
    properties (Abstract, Constant)
        dimension int32
    end
    
    properties (Abstract, Access = public)
        bounds
    end
    
    methods (Abstract)
        fitness = evaluate(obj, solution)
    end
    
    methods
        function tf = isFeasible(obj, solution)
            tf = true;
        end
        
        function fitness = evaluateBatch(obj, population)
            popSize = size(population, 1);
            fitness = zeros(popSize, 1);
            for i = 1:popSize
                fitness(i) = obj.evaluate(population(i, :));
            end
        end
    end
end
```

---

## 4 性能优化指南

### 4.1 数据结构选择

种群表示是元启发式算法中最核心的数据结构，选择不当将严重影响整体性能。对于连续优化问题，须使用 MATLAB 的矩阵存储种群，利用向量化操作替代显式循环，通常可获得 10～100 倍的性能提升。对于组合优化问题，应根据问题特性选择合适的专用数据结构，如排列问题使用整数数组，图问题使用稀疏矩阵等。

```matlab
% ✗ 错误示例：显式循环
fitness = zeros(popSize, 1);
for i = 1:popSize
    fitness(i) = problem.evaluate(population(i, :));
end

% ✓ 正确示例：矩阵化初始化
population = lb + (ub - lb) .* rand(popSize, dim);

% ✓ 更优：批量评估接口（向量化）
fitness = problem.evaluateBatch(population);
```

### 4.2 并行计算支持

对于评估函数耗时较长的场景（如仿真模型、有限元分析等），须支持并行适应度评估。平台提供统一的并行执行器接口，支持 `parfor`（CPU密集型）和异步（IO密集型）两种模式：

```matlab
% utils/ParallelEvaluator.m
classdef ParallelEvaluator < handle
    properties
        mode char = 'parfor'
        maxWorkers int32 = 4
    end
    
    methods
        function obj = ParallelEvaluator(mode, maxWorkers)
            if nargin > 0
                obj.mode = mode;
            end
            if nargin > 1
                obj.maxWorkers = maxWorkers;
            end
        end
        
        function fitness = evaluateBatch(obj, problem, population)
            popSize = size(population, 1);
            fitness = zeros(popSize, 1);
            
            if strcmp(obj.mode, 'parfor')
                % 并行池初始化
                pool = gcp('nocreate');
                if isempty(pool)
                    pool = parpool(obj.maxWorkers);
                end
                
                parfor i = 1:popSize
                    fitness(i) = problem.evaluate(population(i, :));
                end
            else
                % 串行模式
                for i = 1:popSize
                    fitness(i) = problem.evaluate(population(i, :));
                end
            end
        end
    end
end
```

```matlab
% 算法中启用并行评估
evaluator = ParallelEvaluator('parfor', 8);
fitness = evaluator.evaluateBatch(problem, population);
```

### 4.3 循环与内存优化

在迭代主循环中，应尽量减少内存分配次数，优先采用原地更新（in-place update）策略。种群矩阵应在初始化时一次性分配，迭代过程中通过索引操作避免数据复制。此外，对频繁调用的计算结果应实施适当的缓存策略，避免重复计算，尤其是在评估函数代价高昂时。

```matlab
% ✓ 预分配内存
population = zeros(popSize, dim);
fitness = zeros(popSize, 1);
convergenceCurve = zeros(maxIterations, 1);

% ✓ 原地更新
population(indices, :) = newIndividuals;
fitness(indices) = newFitness;

% ✓ 使用持久变量缓存
function cachedValue = expensiveComputation(x)
    persistent cache
    if isempty(cache)
        cache = containers.Map();
    end
    key = mat2str(x);
    if isKey(cache, key)
        cachedValue = cache(key);
    else
        cachedValue = computeExpensiveValue(x);
        cache(key) = cachedValue;
    end
end
```

### 4.4 性能基准指标

各算法实现须满足以下最低性能要求，确保工程可用性：

| 指标 | 最低要求 | 推荐标准 |
|------|----------|----------|
| 初始化时间（1000个体×100维） | < 100ms | < 50ms |
| 单代迭代时间（不含评估） | < 10ms | < 5ms |
| 内存占用（1000个体×100维） | < 50MB | < 20MB |
| 并行加速比（8核） | > 4x | > 6x |
| API 响应时间 | < 200ms | < 100ms |

---

## 5 文档与注释标准

### 5.1 模块级文档

每个算法模块须在文件头部包含完整的模块文档字符串，内容涵盖：算法名称与简介、理论依据及参考文献、关键参数说明、时间复杂度与空间复杂度分析、适用场景与已知局限性。

```matlab
classdef GeneticAlgorithm < BaseAlgorithm
    % GeneticAlgorithm 遗传算法（Genetic Algorithm, GA）实现
    %
    % 基于自然选择和遗传机制的进化计算算法。通过选择、交叉、变异操作
    % 模拟生物进化过程，逐步优化种群中个体的适应度。
    %
    % 参考文献：
    %   [1] Holland, J. H. (1975). Adaptation in Natural and Artificial Systems.
    %   [2] Goldberg, D. E. (1989). Genetic Algorithms in Search, Optimization,
    %       and Machine Learning.
    %
    % 时间复杂度：O(G × N × D)，其中 G=迭代次数，N=种群大小，D=问题维度
    % 空间复杂度：O(N × D)
    %
    % 适用场景：连续/离散优化、多峰函数、组合优化问题
    % 已知局限：高维问题收敛较慢；对参数敏感性较高
    %
    % 使用示例：
    %   problem = SphereProblem(30);
    %   ga = GeneticAlgorithm(struct('populationSize', 50));
    %   result = ga.run(problem);
    %   fprintf('Best fitness: %.6f\n', result.bestFitness);
    
    properties
        % ...
    end
end
```

### 5.2 函数与方法文档

所有公开方法须采用 MATLAB 标准的文档注释格式，须包含功能说明、参数类型与说明、返回值描述、可能抛出的异常以及使用示例：

```matlab
function result = run(obj, problem, maxIterations)
    % RUN 执行元启发式优化过程并返回结果
    %
    % 语法：
    %   result = algorithm.run(problem)
    %   result = algorithm.run(problem, maxIterations)
    %
    % 输入参数：
    %   problem        - BaseProblem 实例，符合接口规范的优化问题
    %   maxIterations  - (可选) 最大迭代次数，默认使用配置中的值
    %
    % 输出参数：
    %   result         - OptimizationResult 对象，包含最优解、收敛曲线等信息
    %
    % 异常：
    %   AlgorithmConfigError      - 配置参数不合法时抛出
    %   ProblemEvaluationError    - 目标函数评估失败时抛出
    %   TimeoutError              - 运行时间超过配置上限时抛出
    %
    % 示例：
    %   problem = SphereProblem(30);
    %   ga = GeneticAlgorithm(struct('populationSize', 50));
    %   result = ga.run(problem);
    %   fprintf('Best fitness: %.6f\n', result.bestFitness);
    
    if nargin < 3 || isempty(maxIterations)
        maxIterations = obj.config.maxIterations;
    end
    
    % ... 实现代码
end
```

### 5.3 算法参数元数据

每个算法类须声明 `PARAM_SCHEMA` 常量属性，定义所有可配置参数的类型、默认值、合法范围及说明。该元数据将被 API 自动提取并暴露给前端，用于动态生成参数配置界面。

```matlab
classdef GeneticAlgorithm < BaseAlgorithm
    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 50, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '种群个体数量，值越大搜索越全面但耗时越长'), ...
            'mutationRate', struct(...
                'type', 'float', ...
                'default', 0.01, ...
                'min', 0.0, ...
                'max', 1.0, ...
                'description', '基因变异概率，通常设为 1/D（D为问题维度）'), ...
            'crossoverRate', struct(...
                'type', 'float', ...
                'default', 0.9, ...
                'min', 0.0, ...
                'max', 1.0, ...
                'description', '交叉概率，控制两个个体交换基因的频率'), ...
            'selection', struct(...
                'type', 'enum', ...
                'options', {{'tournament', 'roulette', 'rank'}}, ...
                'default', 'tournament', ...
                'description', '选择算子类型') ...
        );
    end
    
    % ... 其他代码
end
```

---

## 6 测试与验证要求

### 6.1 单元测试标准

每个算法模块须配备完整的单元测试，测试覆盖率要求不低于 85%（核心逻辑不低于 95%）。单元测试须覆盖正常流程、边界条件和异常处理三个维度：

```matlab
% tests/unit/TestGeneticAlgorithm.m
classdef TestGeneticAlgorithm < matlab.unittest.TestCase
    properties
        AlgorithmClass = @GeneticAlgorithm
    end
    
    methods (TestMethod)
        function testInitializationValidConfig(testCase)
            % 正常配置下初始化应成功
            config = struct('populationSize', 50);
            ga = testCase.AlgorithmClass(config);
            testCase.assertEqual(ga.config.populationSize, 50);
        end
        
        function testInitializationInvalidConfig(testCase)
            % 非法配置应抛出 AlgorithmConfigError
            config = struct('populationSize', -1);
            testCase.assertError(@() testCase.AlgorithmClass(config), ...
                'AlgorithmConfigError');
        end
        
        function testRunReturnsValidResult(testCase)
            % 运行结果须符合 OptimizationResult 结构
            config = struct('maxIterations', 10);
            ga = testCase.AlgorithmClass(config);
            problem = SphereProblem(10);
            
            result = ga.run(problem);
            
            testCase.assertIsInstance(result, 'OptimizationResult');
            testCase.assertIsInstance(result.bestFitness, 'double');
            testCase.assertEqual(length(result.convergenceCurve), 10);
            testCase.assertTrue(result.totalEvaluations > 0);
        end
        
        function testFitnessImprovesOverIterations(testCase)
            % 收敛曲线须单调不增（最小化问题）
            config = struct('maxIterations', 50, 'seed', 42);
            ga = testCase.AlgorithmClass(config);
            problem = SphereProblem(10);
            
            result = ga.run(problem);
            curve = result.convergenceCurve;
            
            for i = 1:(length(curve)-1)
                testCase.assertTrue(curve(i) >= curve(i+1), ...
                    sprintf('Convergence not monotonic at iteration %d', i));
            end
        end
    end
end
```

### 6.2 算法性能验证（标准测试函数）

新实现的算法须在国际通用基准测试函数上进行验证，达到如下精度要求方可合并入主分支：

| 测试函数 | 维度 | 最大函数评估次数 | 精度要求 |
|----------|------|------------------|----------|
| Sphere | 30 | 50,000 | < 1e-10 |
| Rosenbrock | 30 | 100,000 | < 1e-2 |
| Rastrigin | 30 | 100,000 | < 1e-5 |
| Ackley | 30 | 50,000 | < 1e-5 |
| Griewank | 30 | 50,000 | < 1e-8 |

```matlab
% 基准测试示例
function testSphereBenchmark(testCase)
    problem = SphereProblem(30);
    config = struct('populationSize', 50, 'maxIterations', 1000, 'seed', 42);
    ga = GeneticAlgorithm(config);
    
    result = ga.run(problem);
    
    testCase.assertTrue(result.bestFitness < 1e-10, ...
        sprintf('Sphere benchmark failed: got %.2e, expected < 1e-10', ...
        result.bestFitness));
end
```

### 6.3 集成测试与回归测试

集成测试须覆盖从 API 请求到结果返回的完整链路，重点验证：参数序列化与反序列化的正确性、并发请求下的线程安全性、超时与任务取消的正确处理。所有已修复的 Bug 须添加对应的回归测试用例，防止问题复现。

> **📌 注意：** 测试须使用固定随机种子（`rng(seed)`）确保结果可复现。CI/CD 流水线须在合并前自动运行全量测试套件，且所有测试必须通过，不允许跳过测试。

```matlab
% 设置随机种子确保可复现性
rng(42, 'twister');
```

---

## 7 错误处理机制

### 7.1 异常层次体系

```
MetaheuristicError (基础异常)
├── AlgorithmConfigError       # 配置参数非法
│   ├── InvalidParamError      # 参数类型/范围错误
│   └── MissingParamError      # 缺少必要参数
├── ProblemDefinitionError     # 问题定义错误
│   ├── DimensionMismatchError # 维度不一致
│   └── BoundsError            # 边界定义非法
├── AlgorithmRuntimeError      # 运行时错误
│   ├── ConvergenceError       # 无法收敛
│   ├── EvaluationError        # 目标函数评估失败
│   └── TimeoutError           # 超时
└── ResourceError             # 资源错误
    ├── MemoryError            # 内存不足
    └── ConcurrencyError       # 并发冲突
```

MATLAB 实现示例：

```matlab
% 核心异常基类
classdef MetaheuristicError < MException
    methods
        function obj = MetaheuristicError(msg, varargin)
            obj = obj@MException('Metaheuristic:Error', sprintf(msg, varargin{:}));
        end
    end
end

% 配置异常
classdef AlgorithmConfigError < MetaheuristicError
    methods
        function obj = AlgorithmConfigError(msg, varargin)
            obj = obj@MetaheuristicError(msg, varargin{:});
            obj.identifier = 'Metaheuristic:ConfigError';
        end
    end
end

% 参数无效异常
classdef InvalidParamError < AlgorithmConfigError
    properties
        paramName char
        paramValue
        validRange
    end
    
    methods
        function obj = InvalidParamError(paramName, paramValue, validRange)
            obj.paramName = paramName;
            obj.paramValue = paramValue;
            obj.validRange = validRange;
            
            msg = sprintf('参数 %s 的值 %s 超出合法范围 %s', ...
                paramName, string(paramValue), string(validRange));
            obj = obj@AlgorithmConfigError(msg);
            obj.identifier = 'Metaheuristic:InvalidParam';
        end
    end
end
```

### 7.2 错误码体系

| 错误码 | 异常类型 | 说明 |
|--------|----------|------|
| ERR_1001 | InvalidParamError | 参数类型/范围错误 |
| ERR_1002 | MissingParamError | 缺少必要参数 |
| ERR_2001 | DimensionMismatchError | 维度不一致 |
| ERR_2002 | BoundsError | 边界定义非法 |
| ERR_3001 | ConvergenceError | 无法收敛 |
| ERR_3002 | EvaluationError | 目标函数评估失败 |
| ERR_3003 | TimeoutError | 超时 |
| ERR_4001 | MemoryError | 内存不足 |
| ERR_4002 | ConcurrencyError | 并发冲突 |

### 7.3 统一错误响应格式

所有 API 错误须以统一的 JSON 格式返回，包含错误码、人类可读描述、定位细节以及可选的排查建议：

```json
{
  "status": "error",
  "error": {
    "code": "ERR_1001",
    "message": "参数 population_size 的值 -5 超出合法范围 [10, 10000]",
    "field": "config.population_size",
    "suggestion": "请将 population_size 设置为 10 到 10000 之间的整数",
    "docs_url": "https://docs.platform.com/errors/ERR_1001"
  },
  "request_id": "req_xyz789",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

---

## 8 版本控制与兼容性

### 8.1 版本号规范

本平台严格遵循语义化版本控制规范（Semantic Versioning 2.0.0）。版本号格式为 `MAJOR.MINOR.PATCH`，其中：

- **MAJOR** 版本号在进行不兼容的 API 变更时递增
- **MINOR** 版本号在向后兼容的功能性新增时递增
- **PATCH** 版本号在向后兼容的问题修正时递增

```
% 版本示例与含义
1.0.0  →  首次正式发布
1.1.0  →  新增 WhaleOptimization 算法（向后兼容）
1.1.1  →  修复 PSO 边界处理 Bug
2.0.0  →  OptimizationResult 结构重构（破坏性变更）

% API 路径中的版本号
/api/v1/algorithms/...   →  v1.x.x 系列（兼容维护）
/api/v2/algorithms/...   →  v2.x.x 系列（并行运行过渡期）
```

### 8.2 向后兼容性保障

每次发布前须执行兼容性检查矩阵：对所有已公开的 API 端点运行契约测试（Contract Testing），确保新版本响应结构对旧版客户端仍然有效。允许新增字段，但禁止删除或重命名已有字段。如必须进行破坏性变更，须进行至少一个 MINOR 版本的弃用期（Deprecation Period），并在响应头中添加 `Deprecation` 和 `Sunset` 标识：

```
# 弃用声明示例（响应头）
Deprecation: true
Sunset: 2025-07-01
Link: <https://docs.platform.com/migration/v2>; rel="successor-version"
```

```json
# 弃用警告（响应体）
{
  "status": "success",
  "warnings": [
    {
      "code": "DEPRECATED_FIELD",
      "message": "字段 convergence_history 已弃用，请使用 convergence_curve",
      "sunset_date": "2025-07-01"
    }
  ],
  "result": { ... }
}
```

### 8.3 变更日志规范

每个版本须维护符合 [Keep a Changelog](https://keepachangelog.com/) 格式的 `CHANGELOG.md`。变更记录按以下六类组织：

- **Added（新增）**：新功能
- **Changed（变更）**：现有功能的变更
- **Deprecated（弃用）**：即将移除的功能
- **Removed（移除）**：已移除的功能
- **Fixed（修复）**：Bug 修复
- **Security（安全）**：安全相关修复

每条记录中须注明关联的 Issue 或 PR 编号，便于追溯。

---

## 附录 快速入门检查清单

开发人员在提交新算法实现前，须逐项确认以下检查清单中的所有条目：

| 检查项 | 说明 |
|--------|------|
| ☐ 代码结构 | 目录结构符合 §1.1 规范，命名遵循 §1.2 约定 |
| ☐ 抽象基类 | 继承 `BaseAlgorithm`，实现全部抽象方法 |
| ☐ 算法注册 | 调用 `AlgorithmRegistry.register()` 完成注册 |
| ☐ 参数 Schema | `PARAM_SCHEMA` 已完整声明，含默认值与范围说明 |
| ☐ 文档注释 | 所有公开方法均有完整的 MATLAB 文档注释 |
| ☐ 模块文档 | 文件头部包含算法简介、参考文献、复杂度分析 |
| ☐ 单元测试 | 覆盖率 ≥ 85%，含正常/边界/异常三类测试 |
| ☐ 基准测试 | 在 5 个标准函数上达到 §6.2 规定精度 |
| ☐ 错误处理 | 所有异常均使用 §7.1 体系中的类型，含有效错误码 |
| ☐ 并行支持 | 配置 `parallel: true` 时算法可正常运行 |
| ☐ 性能验证 | 满足 §4.4 所有性能基准指标 |
| ☐ 集成测试 | API 端到端测试通过，CI 流水线全绿 |
| ☐ 变更日志 | `CHANGELOG.md` 已按规范更新 |
| ☐ 版本号 | `projectConfig.m` 中版本号已按 §8.1 正确递增 |

---

*本规范由 RUOFENG YU 负责制定与维护*

*如有疑问或改进建议，请通过内部工单系统提交*
