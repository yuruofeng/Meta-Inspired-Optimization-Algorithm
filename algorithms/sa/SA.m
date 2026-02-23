classdef SA < BaseAlgorithm
    % SA 模拟退火算法 (Simulated Annealing)
    %
    % 一种单解元启发式算法，模拟金属退火过程。通过温度调度和
    % Metropolis准则，具有跳出局部最优的能力。
    %
    % 算法原理:
    %   1. 初始化温度和解
    %   2. 生成邻居解
    %   3. 若新解更优，直接接受
    %   4. 否则以概率 P = exp(-ΔE/T) 接受
    %   5. 按冷却率降低温度
    %   6. 重复直到终止条件
    %
    % 参考文献:
    %   S. Kirkpatrick, C. D. Gelatt, M. P. Vecchi
    %   "Optimization by Simulated Annealing"
    %   Science, 1983
    %
    % 时间复杂度: O(MaxIter × IterPerTemp)
    % 空间复杂度: O(Dim)
    %
    % 使用示例:
    %   config = struct('initialTemp', 100, 'finalTemp', 1e-6, ...
    %                   'coolingRate', 0.99, 'maxIterations', 1000);
    %   sa = SA(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = sa.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        currentSolution      % 当前解 (1 x Dim)
        currentFitness       % 当前适应度
        temperature          % 当前温度
        neighborGenerator    % 邻居生成器
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'initialTemp', struct(...
                'type', 'float', ...
                'default', 100, ...
                'min', 0, ...
                'description', '初始温度'), ...
            'finalTemp', struct(...
                'type', 'float', ...
                'default', 1e-6, ...
                'min', 0, ...
                'description', '终止温度'), ...
            'coolingRate', struct(...
                'type', 'float', ...
                'default', 0.99, ...
                'min', 0, ...
                'max', 1, ...
                'description', '冷却率 (alpha)'), ...
            'iterationsPerTemp', struct(...
                'type', 'integer', ...
                'default', 10, ...
                'min', 1, ...
                'description', '每个温度的迭代次数'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 1000, ...
                'min', 1, ...
                'description', '最大迭代次数 (总迭代)'), ...
            'neighborType', struct(...
                'type', 'enum', ...
                'options', {{'gaussian', 'uniform', 'cauchy'}}, ...
                'default', 'gaussian', ...
                'description', '邻居生成策略'), ...
            'stepSize', struct(...
                'type', 'float', ...
                'default', 0.1, ...
                'min', 0, ...
                'description', '邻居步长 (相对于搜索范围的比例)'), ...
            'adaptiveStep', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否使用温度自适应步长'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = SA(configStruct)
            % SA 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - initialTemp: 初始温度 (默认: 100)
            %     - finalTemp: 终止温度 (默认: 1e-6)
            %     - coolingRate: 冷却率 (默认: 0.99)
            %     - iterationsPerTemp: 每温度迭代次数 (默认: 10)
            %     - maxIterations: 最大迭代次数 (默认: 1000)
            %     - neighborType: 邻居类型 (默认: 'gaussian')
            %     - stepSize: 步长比例 (默认: 0.1)
            %     - adaptiveStep: 是否自适应步长 (默认: true)
            %     - verbose: 是否显示进度 (默认: true)

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@BaseAlgorithm(configStruct);
        end

        function initialize(obj, problem)
            % initialize 初始化算法
            %
            % 输入参数:
            %   problem - 问题对象，需包含 lb, ub, dim, evaluate 字段

            % 获取问题参数
            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            MaxIter = obj.config.maxIterations;

            % 随机初始化当前解
            if isscalar(lb)
                obj.currentSolution = lb + (ub - lb) * rand(1, dim);
            else
                obj.currentSolution = lb + (ub - lb) .* rand(1, dim);
            end

            % 评估初始解
            obj.currentFitness = obj.evaluateSolution(obj.currentSolution);

            % 初始化全局最优
            obj.bestSolution = obj.currentSolution;
            obj.bestFitness = obj.currentFitness;

            % 初始化温度
            obj.temperature = obj.config.initialTemp;

            % 初始化邻居生成器
            obj.neighborGenerator = NeighborGenerator(...
                'neighborType', obj.config.neighborType, ...
                'stepSize', obj.config.stepSize);

            % 预分配收敛曲线
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括邻居生成、接受判断、温度更新

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            currentIter = obj.currentIteration + 1;
            iterPerTemp = obj.config.iterationsPerTemp;

            % 执行每个温度的多次迭代
            for subIter = 1:iterPerTemp
                % 生成邻居解
                if obj.config.adaptiveStep
                    neighbor = obj.neighborGenerator.generateWithScale(...
                        obj.currentSolution, lb, ub, ...
                        obj.temperature, obj.config.initialTemp);
                else
                    neighbor = obj.neighborGenerator.generate(...
                        obj.currentSolution, lb, ub);
                end

                % 评估邻居
                neighborFitness = obj.evaluateSolution(neighbor);

                % 接受判断
                if obj.acceptSolution(neighborFitness, obj.currentFitness, obj.temperature)
                    obj.currentSolution = neighbor;
                    obj.currentFitness = neighborFitness;

                    % 更新全局最优
                    if neighborFitness < obj.bestFitness
                        obj.bestFitness = neighborFitness;
                        obj.bestSolution = neighbor;
                    end
                end
            end

            % 降温
            obj.temperature = obj.temperature * obj.config.coolingRate;

            % 记录收敛曲线
            obj.convergenceCurve(currentIter) = obj.bestFitness;

            % 显示进度
            if obj.config.verbose && mod(currentIter, 100) == 0
                obj.displayProgress(sprintf('T=%.2e, Best=%.6e', ...
                    obj.temperature, obj.bestFitness));
            end
        end

        function tf = shouldStop(obj)
            % shouldStop 判断是否停止迭代
            %
            % 输出参数:
            %   tf - true表示停止，false表示继续
            %
            % 说明:
            %   当达到最大迭代次数或温度低于终止温度时停止

            tf = obj.currentIteration >= obj.config.maxIterations || ...
                 obj.temperature < obj.config.finalTemp;
        end

        function validatedConfig = validateConfig(obj, config)
            % validateConfig 验证并规范化配置参数
            %
            % 输入参数:
            %   config - 原始配置结构体
            %
            % 输出参数:
            %   validatedConfig - 验证后的配置结构体

            validatedConfig = struct();

            % 初始温度
            if isfield(config, 'initialTemp')
                validatedConfig.initialTemp = config.initialTemp;
            else
                validatedConfig.initialTemp = 100;
            end

            if validatedConfig.initialTemp <= 0
                error('SA:InvalidConfig', 'initialTemp must be > 0');
            end

            % 终止温度
            if isfield(config, 'finalTemp')
                validatedConfig.finalTemp = config.finalTemp;
            else
                validatedConfig.finalTemp = 1e-6;
            end

            if validatedConfig.finalTemp < 0
                error('SA:InvalidConfig', 'finalTemp must be >= 0');
            end

            % 冷却率
            if isfield(config, 'coolingRate')
                validatedConfig.coolingRate = config.coolingRate;
            else
                validatedConfig.coolingRate = 0.99;
            end

            if validatedConfig.coolingRate <= 0 || validatedConfig.coolingRate > 1
                error('SA:InvalidConfig', 'coolingRate must be in (0, 1]');
            end

            % 每温度迭代次数
            if isfield(config, 'iterationsPerTemp')
                validatedConfig.iterationsPerTemp = config.iterationsPerTemp;
            else
                validatedConfig.iterationsPerTemp = 10;
            end

            if validatedConfig.iterationsPerTemp < 1
                error('SA:InvalidConfig', 'iterationsPerTemp must be >= 1');
            end

            % 最大迭代次数
            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 1000;
            end

            if validatedConfig.maxIterations < 1
                error('SA:InvalidConfig', 'maxIterations must be >= 1');
            end

            % 邻居类型
            if isfield(config, 'neighborType')
                validatedConfig.neighborType = validatestring(config.neighborType, ...
                    {'gaussian', 'uniform', 'cauchy'});
            else
                validatedConfig.neighborType = 'gaussian';
            end

            % 步长
            if isfield(config, 'stepSize')
                validatedConfig.stepSize = config.stepSize;
            else
                validatedConfig.stepSize = 0.1;
            end

            if validatedConfig.stepSize <= 0
                error('SA:InvalidConfig', 'stepSize must be > 0');
            end

            % 自适应步长
            if isfield(config, 'adaptiveStep')
                validatedConfig.adaptiveStep = config.adaptiveStep;
            else
                validatedConfig.adaptiveStep = true;
            end

            % 详细输出
            if isfield(config, 'verbose')
                validatedConfig.verbose = config.verbose;
            else
                validatedConfig.verbose = true;
            end
        end
    end

    methods (Access = protected)
        function accept = acceptSolution(obj, newFitness, currentFitness, temperature)
            % acceptSolution Metropolis接受准则
            %
            % 输入参数:
            %   newFitness - 新解的适应度
            %   currentFitness - 当前解的适应度
            %   temperature - 当前温度
            %
            % 输出参数:
            %   accept - 是否接受新解

            if newFitness < currentFitness
                % 新解更优，直接接受
                accept = true;
            else
                % 计算接受概率
                delta = newFitness - currentFitness;
                if temperature > 0
                    P = exp(-delta / temperature);
                else
                    P = 0;
                end
                accept = rand() < P;
            end
        end
    end

    methods (Static)
        function register()
            % register 将SA算法注册到算法注册表
            %
            % 示例:
            %   SA.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('SA');

            AlgorithmRegistry.register('SA', '2.0.0', @SA);
        end
    end
end
