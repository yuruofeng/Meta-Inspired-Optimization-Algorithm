classdef ALO < BaseAlgorithm
    % ALO 蚁狮优化器 (Ant Lion Optimizer)
    %
    % 一种模拟蚁狮狩猎行为的元启发式算法。通过蚁狮构建陷阱、蚂蚁随机游走、
    % 以及精英保留机制实现全局优化。
    %
    % 参考文献:
    %   S. Mirjalili, "The Ant Lion Optimizer"
    %   Advances in Engineering Software, 2015
    %   DOI: 10.1016/j.advengsoft.2015.01.010
    %
    % 时间复杂度: O(MaxIter × N × Dim)
    % 空间复杂度: O(N × Dim)
    %
    % 使用示例:
    %   config = struct('populationSize', 30, 'maxIterations', 500);
    %   alo = ALO(config);
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %   problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    %   result = alo.run(problem);
    %   fprintf('Best fitness: %.6e\n', result.bestFitness);
    %
    % 原始作者: Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties (Access = protected)
        antlionPositions      % 蚁狮位置矩阵 (N x Dim)
        antPositions          % 蚂蚁位置矩阵 (N x Dim)
        antlionsFitness       % 蚁狮适应度向量 (1 x N)
        elitePosition         % 精英蚁狮位置 (1 x Dim)
        eliteFitness          % 精英蚁狮适应度
        rouletteSelector      % 轮盘赌选择器
        randomWalker          % 随机游走器
    end

    properties (Constant)
        PARAM_SCHEMA = struct(...
            'populationSize', struct(...
                'type', 'integer', ...
                'default', 30, ...
                'min', 10, ...
                'max', 10000, ...
                'description', '蚁狮/蚂蚁种群个体数量'), ...
            'maxIterations', struct(...
                'type', 'integer', ...
                'default', 500, ...
                'min', 1, ...
                'max', 100000, ...
                'description', '最大迭代次数'), ...
            'verbose', struct(...
                'type', 'boolean', ...
                'default', true, ...
                'description', '是否显示进度信息') ...
        )
    end

    methods
        function obj = ALO(configStruct)
            % ALO 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，可选字段:
            %     - populationSize: 种群大小 (默认: 30)
            %     - maxIterations: 最大迭代次数 (默认: 500)
            %     - verbose: 是否显示进度 (默认: true)

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj = obj@BaseAlgorithm(configStruct);

            % 初始化算子
            obj.rouletteSelector = RouletteWheelSelection();
            obj.randomWalker = RandomWalk();
        end

        function initialize(obj, problem)
            % initialize 初始化种群
            %
            % 输入参数:
            %   problem - 问题对象，需包含 lb, ub, dim 字段

            % 获取问题参数
            lb = problem.lb;
            ub = problem.ub;
            dim = problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;

            % 初始化蚁狮和蚂蚁种群
            obj.antlionPositions = Initialization(N, dim, ub, lb);
            obj.antPositions = Initialization(N, dim, ub, lb);

            % 评估初始蚁狮适应度
            obj.antlionsFitness = zeros(1, N);
            for i = 1:N
                obj.antlionsFitness(i) = obj.evaluateSolution(obj.antlionPositions(i, :));
            end

            % 排序蚁狮
            [sortedFitness, sortedIndices] = sort(obj.antlionsFitness);
            obj.antlionPositions = obj.antlionPositions(sortedIndices, :);
            obj.antlionsFitness = sortedFitness;

            % 初始化精英
            obj.elitePosition = obj.antlionPositions(1, :);
            obj.eliteFitness = obj.antlionsFitness(1);
            obj.bestFitness = obj.eliteFitness;
            obj.bestSolution = obj.elitePosition;

            % 预分配收敛曲线
            obj.convergenceCurve = zeros(MaxIter, 1);
        end

        function iterate(obj)
            % iterate 执行一次迭代
            %
            % 包括蚂蚁随机游走、边界检查、适应度评估、蚁狮更新和精英更新

            lb = obj.problem.lb;
            ub = obj.problem.ub;
            dim = obj.problem.dim;
            N = obj.config.populationSize;
            MaxIter = obj.config.maxIterations;
            currentIter = obj.currentIteration + 1; % +1 因为从0开始

            % 蚂蚁随机游走
            for i = 1:N
                % 轮盘赌选择蚁狮
                weights = 1 ./ (obj.antlionsFitness + eps); % 适应度越小权重越大
                selectedIndex = obj.rouletteSelector.select(weights);

                % 随机游走 - 围绕选中的蚁狮
                RA = obj.randomWalker.walk(dim, MaxIter, lb, ub, ...
                    obj.antlionPositions(selectedIndex, :), currentIter);

                % 随机游走 - 围绕精英蚁狮
                RE = obj.randomWalker.walk(dim, MaxIter, lb, ub, ...
                    obj.elitePosition, currentIter);

                % 更新蚂蚁位置 (Equation 2.13)
                obj.antPositions(i, :) = (RA(currentIter, :) + RE(currentIter, :)) / 2;
            end

            % 边界检查
            obj.applyBoundaryConstraints(lb, ub);

            % 评估蚂蚁适应度
            antsFitness = obj.evaluatePopulation(obj.antPositions);

            % 合并蚁狮和蚂蚁种群
            combinedPop = [obj.antlionPositions; obj.antPositions];
            combinedFitness = [obj.antlionsFitness, antsFitness];

            % 排序并选择前N个作为新蚁狮种群
            [sortedFitness, sortedIndices] = sort(combinedFitness);
            obj.antlionPositions = combinedPop(sortedIndices(1:N), :);
            obj.antlionsFitness = sortedFitness(1:N);

            % 更新精英
            if obj.antlionsFitness(1) < obj.eliteFitness
                obj.elitePosition = obj.antlionPositions(1, :);
                obj.eliteFitness = obj.antlionsFitness(1);
            end

            % 精英保留
            obj.antlionPositions(1, :) = obj.elitePosition;
            obj.antlionsFitness(1) = obj.eliteFitness;

            % 更新全局最优
            if obj.eliteFitness < obj.bestFitness
                obj.bestFitness = obj.eliteFitness;
                obj.bestSolution = obj.elitePosition;
            end

            % 记录收敛曲线
            obj.convergenceCurve(currentIter) = obj.bestFitness;

            % 显示进度
            if obj.config.verbose && mod(currentIter, 50) == 0
                obj.displayProgress(sprintf('Best fitness: %.6e', obj.bestFitness));
            end
        end

        function tf = shouldStop(obj)
            % shouldStop 判断是否停止迭代
            %
            % 输出参数:
            %   tf - true表示停止，false表示继续

            tf = obj.currentIteration >= obj.config.maxIterations;
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

            % 种群大小
            if isfield(config, 'populationSize')
                validatedConfig.populationSize = config.populationSize;
            else
                validatedConfig.populationSize = 30;
            end

            if validatedConfig.populationSize < 10
                error('ALO:InvalidConfig', 'populationSize must be >= 10');
            end

            % 最大迭代次数
            if isfield(config, 'maxIterations')
                validatedConfig.maxIterations = config.maxIterations;
            else
                validatedConfig.maxIterations = 500;
            end

            if validatedConfig.maxIterations < 1
                error('ALO:InvalidConfig', 'maxIterations must be >= 1');
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
        function applyBoundaryConstraints(obj, lb, ub)
            % applyBoundaryConstraints 应用边界约束
            %
            % 输入参数:
            %   lb - 下边界
            %   ub - 上边界

            N = size(obj.antPositions, 1);

            for i = 1:N
                % 上边界违反
                flagUb = obj.antPositions(i, :) > ub;
                % 下边界违反
                flagLb = obj.antPositions(i, :) < lb;

                % 修复边界
                obj.antPositions(i, :) = obj.antPositions(i, :) .* ...
                    ~(flagUb | flagLb) + ub .* flagUb + lb .* flagLb;
            end
        end
    end

    methods (Static)
        function register()
            % register 将ALO算法注册到算法注册表
            %
            % 示例:
            %   ALO.register();
            %   algClass = AlgorithmRegistry.getAlgorithm('ALO');

            AlgorithmRegistry.register('ALO', '2.0.0', @ALO);
        end
    end
end
